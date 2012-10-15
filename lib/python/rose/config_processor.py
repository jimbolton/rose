# -*- coding: utf-8 -*-
#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------
"""Process named settings in rose.config.ConfigNode."""

from rose.env import UnboundEnvironmentVariableError
from rose.popen import RosePopener


class UnknownContentError(Exception):

    """Attempt to process an unknown or unsupported content."""

    def __str__(self):
        return "%s: unknown content" % self.args[0]


class ConfigProcessError(Exception):

    """An exception raised when the processing of a setting fails.

    keys: the keys from the root config to the setting.
    value: the value of the setting.
    e: the exception that triggers this exception.

    """

    def __init__(self, keys, value, e=None):
        self.keys = keys
        self.value = value
        self.e = e
        Exception.__init__(self, keys, value, e)

    def __str__(self):
        if isinstance(self.e, UnboundEnvironmentVariableError):
            setting_str = "=".join(list(self.keys))
            return "%s: %s: unbound variable" % (setting_str, self.e.args[0])
        else:
            setting_str = ""
            if self.keys is not None and self.value is not None:
                setting_str = "=".join(list(self.keys) + [self.value])
            e = str(self.e)
            if e is None:
                e = "bad setting"
            return "%s: %s" % (setting_str, e)

class ConfigProcessorBase(object):

    """Base class for a config processor."""

    def __init__(self, manager=None):
        self.manager = manager

    def process(self, config, item, orig_keys=None, orig_value=None):
        pass


class ConfigProcessorsManager(object):

    """Manage the loading of config processors."""

    def __init__(self, event_handler=None, popen=None):
        if event_handler is None:
            event_handler = self._dummy
        self.event_handler = event_handler
        if popen is None:
            popen = RosePopener(event_handler)
        self.popen = popen
        self.processors = {}

    def _dummy(self, *args, **kwargs):
        pass

    def process(self, config, item, orig_keys=None, orig_value=None, scheme=None):
        if scheme is None:
            scheme = item
            if ":" in item:
                scheme = item.split(":", 1)[0]
        if self.processors.get(scheme) is None:
            ns = __name__ + "s"
            try:
                mod = __import__(ns + "." + scheme, fromlist=ns)
            except ImportError as e:
                e = UnknownContentError(item)
                raise ConfigProcessError(orig_keys, orig_value, e)
            for v in vars(mod):
                c = getattr(mod, v)
                base = ConfigProcessorBase
                if isinstance(c, type) and issubclass(c, base) and c != base:
                    self.processors[scheme] = c(self)
                    break
            else:
                raise ConfigProcessError(orig_keys, orig_value)
        processor = self.processors[scheme]
        return processor.process(config, item, orig_keys, orig_value)
    __call__ = process