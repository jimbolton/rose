#!/bin/bash
#-------------------------------------------------------------------------------
# (C) British Crown Copyright 2012 Met Office.
# 
# This file is part of Rose, a framework for scientific suites.
# 
# Rose is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Rose is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Rose. If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------
# Test "rose app-run", generation of files.
#-------------------------------------------------------------------------------
. $(dirname $0)/test_header
init <<'__CONFIG__'
[command]
default = cat hello1 hello2 hello3/text
test-empty = cat hello1 hello2 hello3/text && cmp hello4 /dev/null
test-directory = cat hello1 hello2 hello3/text && test -d hello4/directory
test-sources = cat hello1 hello2 hello3/text hello4/text
__CONFIG__
mkdir -p config/file
cat >config/file/hello1 <<__CONTENT__
Hello $(whoami), how are you?
__CONTENT__
cat >config/file/hello2 <<'__CONTENT__'
Hello world!
Hello earth!
Hello universe!
__CONTENT__
mkdir config/file/hello3
cat >config/file/hello3/text <<'__CONTENT__'
Hello and good bye.
Hello and good bye.
__CONTENT__
OUT=$(cd config/file && cat hello1 hello2 hello3/text)
#-------------------------------------------------------------------------------
tests 30
#-------------------------------------------------------------------------------
# Normal mode with free format files.
TEST_KEY=$TEST_KEY_BASE
setup
run_pass "$TEST_KEY" rose app-run --config=../config -q
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" <<<"$OUT"
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
teardown
#-------------------------------------------------------------------------------
# Normal mode with free format files and an empty file.
TEST_KEY=$TEST_KEY_BASE-empty
setup
run_pass "$TEST_KEY" rose app-run --config=../config -q \
    --command-key=test-empty --define='[file:hello4]'
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" <<<"$OUT"
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
teardown
#-------------------------------------------------------------------------------
# Normal mode with free format files and a file with an invalid content.
TEST_KEY=$TEST_KEY_BASE-invalid-content
setup
run_fail "$TEST_KEY" rose app-run --config=../config -q \
    --define='[file:hello4]content=stuff:ing'
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" </dev/null
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" <<'__CONTENT__'
[FAIL] file:hello4=content=stuff:ing: stuff: unknown content
__CONTENT__
teardown
#-------------------------------------------------------------------------------
# Verbose mode with free format files.
TEST_KEY=$TEST_KEY_BASE-v1
setup
run_pass "$TEST_KEY" rose app-run --config=../config
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" <<__CONTENT__
[INFO] export PATH=$PATH
[INFO] create: hello3
[INFO] install: hello1 <= ../config/file/hello1
[INFO] install: hello2 <= ../config/file/hello2
[INFO] install: hello3/text <= ../config/file/hello3/text
[INFO] command: cat hello1 hello2 hello3/text
$OUT
__CONTENT__
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
teardown
#-------------------------------------------------------------------------------
# Normal mode with free format files and a file with multiple sources.
TEST_KEY=$TEST_KEY_BASE-sources
setup
run_pass "$TEST_KEY" rose app-run --config=../config -q \
    --command-key=test-sources \
    '--define=[file:hello4/text]source=/etc/passwd /etc/profile'
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" <<__CONTENT__
$OUT
$(</etc/passwd)
$(</etc/profile)
__CONTENT__
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
teardown
#-------------------------------------------------------------------------------
# Normal mode with free format files and a directory.
TEST_KEY=$TEST_KEY_BASE-directory
setup
run_pass "$TEST_KEY" rose app-run --config=../config -q \
    --command-key=test-directory \
    --define='[file:hello4/directory]mode=mkdir'
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" <<<"$OUT"
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
teardown
#-------------------------------------------------------------------------------
# Normal mode with free format files and an existing file, with --no-overwrite.
TEST_KEY=$TEST_KEY_BASE--no-overwrite
setup
touch hello1
run_fail "$TEST_KEY" rose app-run --config=../config -q --no-overwrite
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" </dev/null
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" <<'__CONTENT__'
[FAIL] file:hello1: hello1: file already exists (and in no-overwrite mode)
__CONTENT__
teardown
#-------------------------------------------------------------------------------
# Normal mode with free format files, overwrite an existing file.
TEST_KEY=$TEST_KEY_BASE-overwrite
setup
touch hello1
run_pass "$TEST_KEY" rose app-run --config=../config -q
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" <<<"$OUT"
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
teardown
#-------------------------------------------------------------------------------
# Install-only mode with free format files.
TEST_KEY=$TEST_KEY_BASE--install-only
setup
run_pass "$TEST_KEY" rose app-run --config=../config --install-only
file_cmp "$TEST_KEY.out" "$TEST_KEY.out" <<__CONTENT__
[INFO] export PATH=$PATH
[INFO] create: hello3
[INFO] install: hello1 <= ../config/file/hello1
[INFO] install: hello2 <= ../config/file/hello2
[INFO] install: hello3/text <= ../config/file/hello3/text
[INFO] command: cat hello1 hello2 hello3/text
__CONTENT__
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
file_cmp "$TEST_KEY.hello1" hello1 ../config/file/hello1
file_cmp "$TEST_KEY.hello2" hello2 ../config/file/hello2
file_cmp "$TEST_KEY.hello3" hello3/text ../config/file/hello3/text
teardown
#-------------------------------------------------------------------------------
exit
