#   Copyright 2008 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
from wallabyclient.exceptions import *
from yaml import YAMLObject
from WallabyHelpers import get_node


class WallabyBaseObject(YAMLObject):
   def __init__(self, name):
      self.name = name


   def get_name(self):
      return self.name


   def validate(self, orig):
      warnings = {}

      for key in dir(orig):
         if hasattr(self, key) == False:
            warnings[key] = 'Field missing.  Resetting to pre-edit value'
         elif getattr(self, key).__class__ != getattr(orig, key).__class__:
            warnings[key] = 'Invalid value.  Resetting to pre-edit value'
            

         if key in warnings.keys():
            setattr(self, key, getattr(orig, key))

      if warnings != {}:
         raise ValidateWarning(warnings)


class Feature(WallabyBaseObject):
   yaml_tag = u'!Feature'
   def __init__(self, name, params={}, includes=[], conflicts=[], depends=[]):
      WallabyBaseObject.__init__(self, str(name))
      self.params = dict(params)
      self.includes = list(includes)
      self.conflicts = list(conflicts)
      self.depends = list(depends)


   def __repr__(self):
      return '%s(name=%r, params=%r, includes=%r, conflicts=%r, depends=%r' % (self.__class__.__name__, self.name, self.params, self.includes, self.conflicts, self.depends)


   def dict_as_list(self):
      return [('name',self.name), ('params',self.params), ('includes',self.includes), ('conflicts',self.conflicts), ('depends',self.depends)]


   def init_from_obj(self, obj):
      param_meta = obj.param_meta
      for meta in param_meta.keys():
         if param_meta[meta]['uses_default'] == True:
            self.params[meta] = ''
         else:
            self.params[meta] = param_meta[meta]['given_value']

      self.includes = list(obj.included_features)
      self.conflicts = list(obj.conflicts)
      self.depends = list(obj.depends)


   def validate(self, orig):
      for param in self.params:
         self.params[param] = str(self.params[param])
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      invalid = {}
      errors = {}
      ask_default = []

      if self.params != None and isinstance(self.params, dict):
         result = store.checkParameterValidity(self.params.keys())
         invalid['Parameter'] = []
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               invalid['Parameter'] = result.outArgs['invalidParameters']

         for p in self.params.keys():
            if self.params[p] != None and \
               isinstance(self.params[p], str) and \
               self.params[p].strip() == '':
               ask_default += [p]

      invalid['Feature'] = []
      if self.includes != None and isinstance(self.includes, list):
         result = store.checkFeatureValidity(self.includes)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidFeatures'] != []:
               invalid['Feature'] = result.outArgs['invalidFeatures']

      if self.conflicts != None and isinstance(self.conflicts, list):
         result = store.checkFeatureValidity(self.conflicts)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidFeatures'] != []:
               invalid['Feature'] = invalid['Feature'] + result.outArgs['invalidFeatures']

      if self.depends != None and isinstance(self.depends, list):
         result = store.checkFeatureValidity(self.depends)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidFeatures'] != []:
               invalid['Feature'] = invalid['Feature'] + result.outArgs['invalidFeatures']

      if invalid != {} or errors != {} or ask_default != []:
         raise WallabyValidateError(invalid, errors, ask_default)


   def set_use_default_val(self, name):
      self.params[name.strip()] = 0


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No feature object to update'})

      result = obj.modifyParams('replace', self.params, {})
      if result.status != 0:
          errors[result.status] = result.text

      result = obj.modifyIncludedFeatures('replace', self.includes, {})
      if result.status != 0:
          errors[result.status] = result.text

      result = obj.modifyConflicts('replace', self.conflicts, {})
      if result.status != 0:
          errors[result.status] = result.text

      result = obj.modifyDepends('replace', self.depends, {})
      if result.status != 0:
          errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)


class Parameter(WallabyBaseObject):
   yaml_tag = u'!Parameter'
   def __init__(self, name, type='', default='', desc='', change=True, level=0, restart=False, depends=[], conflicts=[]):
      WallabyBaseObject.__init__(self, str(name))
      self.type = str(type)
      self.default = str(default)
      self.description = str(desc)
      self.must_change = bool(change)
      self.level = int(level)
      self.restart = bool(restart)
      self.depends = list(depends)
      self.conflicts = list(conflicts)


   def __repr__(self):
      return '%s(name=%r, type=%r, default_value=%r, description=%r, must_change=%r, expert_level=%r, requires_restart=%r, parameter_dependencies=%r, parameter_conflicts=%r' % (self.__class__.__name__, self.name, self.type, self.default, self.description, self.must_change, self.level, self.restart, self.depends, self.conflicts)


   def dict_as_list(self):
      return [('name',self.name), ('type',self.type), ('default',self.default), ('description',self.description), ('must_change',self.must_change), ('level',self.level), ('restart',self.restart), ('depends',self.depends), ('conflicts',self.conflicts)]


   def init_from_obj(self, obj):
      self.type = str(obj.kind)
      self.default = str(obj.default)
      self.description = str(obj.description)
      self.must_change = bool(obj.must_change)
      self.level = int(obj.visibility_level)
      self.restart = bool(obj.requires_restart)
      self.depends = list(obj.depends)
      self.conflicts = list(obj.conflicts)


   def validate(self, orig):
      self.type = str(self.type)
      self.default = str(self.default)
      self.description = str(self.description)
      self.must_change = bool(self.must_change)
      self.restart = bool(self.restart)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      invalid = {}
      errors = {}

      invalid['Parameter'] = []
      if self.depends != None and isinstance(self.depends, list):
         result = store.checkParameterValidity(self.depends)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               invalid['Parameter'] = result.outArgs['invalidParameters']

      if self.conflicts != None and isinstance(self.conflicts, list):
         result = store.checkParameterValidity(self.conflicts)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               invalid['Parameter'] = invalid['Parameter'] + result.outArgs['invalidParameters']

      if invalid != {} or errors != {}:
         raise WallabyValidateError(invalid, errors, [])


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No parameter object to update'})

      if self.must_change == None:
         self.must_change = False

      result = obj.setMustChange(self.must_change)
      if result.status != 0:
         errors[result.status] = result.text

      result = obj.setKind(self.type)
      if result.status != 0:
         errors[result.status] = result.text

      if self.must_change == False:
         result = obj.setDefault(self.default)
         if result.status != 0:
            errors[result.status] = result.text

      result = obj.setDescription(self.description)
      if result.status != 0:
         errors[result.status] = result.text

      try:
         self.level = int(self.level)
         if self.level < 0:
            self.level = 0
      except:
         self.level = 0
      result = obj.setVisibilityLevel(self.level)
      if result.status != 0:
         errors[result.status] = result.text

      if self.restart == None:
         self.restart = False
      result = obj.setRequiresRestart(self.restart)
      if result.status != 0:
         errors[result.status] = result.text

      result = obj.modifyDepends('replace', self.depends, {})
      if result.status != 0:
         errors[result.status] = result.text

      result = obj.modifyConflicts('replace', self.conflicts, {})
      if result.status != 0:
         errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)


class Node(WallabyBaseObject):
   yaml_tag = u'!Node'
   def __init__(self, name, memberships=[]):
      WallabyBaseObject.__init__(self, str(name))
      self.memberships = list(memberships)


   def __repr__(self):
      return '%s(name=%r, group_membership=%r' % (self.__class__.__name__, self.name, self.memberships)


   def dict_as_list(self):
      return [('name',self.name), ('memberships',self.memberships)]


   def init_from_obj(self, obj):
      self.name = str(obj.name)
      self.memberships = list(obj.memberships)


   def validate(self, orig):
      self.name = str(self.name)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      invalid = {}
      errors = {}

      if self.memberships != None and isinstance(self.memberships, list):
         result = store.checkGroupValidity(self.memberships)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidGroups'] != []:
               invalid['Group'] = result.outArgs['invalidGroups']

      if invalid != {} or errors != {}:
         raise WallabyValidateError(invalid, errors, [])


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No node object to update'})

      result = obj.modifyMemberships('replace', self.memberships, {})
      if result.status != 0:
         errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)


class Subsystem(WallabyBaseObject):
   yaml_tag = u'!Subsystem'
   def __init__(self, name, params=[]):
      WallabyBaseObject.__init__(self, str(name))
      self.params = list(params)


   def __repr__(self):
      return '%s(name=%r, affecting_parameters=%r' % (self.__class__.__name__, self.name, self.params)


   def dict_as_list(self):
      return [('name',self.name), ('params',self.params)]


   def init_from_obj(self, obj):
      self.name = str(obj.name)
      self.params = list(obj.params)


   def validate(self, orig):
      self.name = str(self.name)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      invalid = {}
      errors = {}

      if self.params != None and isinstance(self.params, list):
         result = store.checkParameterValidity(self.params)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               invalid['Parameter'] = result.outArgs['invalidParameters']

      if invalid != {} or errors != {}:
         raise WallabyValidateError(invalid, errors, [])


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No subsystem object to update'})

      result = obj.modifyParams('replace', self.params, {})
      if result.status != 0:
          errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)
