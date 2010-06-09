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
from wallabyclient.exceptions import WallabyError, WallabyValidateError
from yaml import YAMLObject
from WallabyHelpers import get_node


class Feature(YAMLObject):
   yaml_tag = u'!Feature'
   def __init__(self, name, params={}, includes=[], conflicts=[], depends=[]):
      self.name = name
      self.params = dict(params)
      self.includes = list(includes)
      self.conflicts = list(conflicts)
      self.depends = list(depends)


   def __repr__(self):
      return '%s(name=%r, params=%r, includes=%r, conflicts=%r, depends=%r, subsys=%r' % (self.__class__.__name__, self.name, self.params, self.includes, self.conflicts, self.depends, self.subsys)


   def dict_as_list(self):
      return [('name',self.name), ('params',self.params), ('includes',self.includes), ('conflicts',self.conflicts), ('depends',self.depends)]


   def get_name(self):
      return self.name


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


   def store_validate(self, store):
      invalid = {}
      errors = {}
      ask_default = []

      result = store.checkParameterValidity(self.params.keys())
      if result.status != 0:
         errors[result.status] = result.text
      else:
         if result.outArgs['invalidParameters'] != []:
            invalid['Parameter'] = result.outArgs['invalidParameters']

      for p in self.params.keys():
         if self.params[p].strip() == '':
            ask_default += [p]

      result = store.checkFeatureValidity(self.includes)
      if result.status != 0:
         errors[result.status] = result.text
         invalid['Feature'] = []
      else:
         if result.outArgs['invalidFeatures'] != []:
            invalid['Feature'] = result.outArgs['invalidFeatures']

      result = store.checkFeatureValidity(self.conflicts)
      if result.status != 0:
         errors[result.status] = result.text
      else:
         if result.outArgs['invalidFeatures'] != []:
            invalid['Feature'] = invalid['Feature'] + result.outArgs['invalidFeatures']

      result = store.checkFeatureValidity(self.depends)
      if result.status != 0:
         errors[result.status] = result.text
      else:
         if result.outArgs['invalidFeatures'] != []:
            invalid['Feature'] = invalid['Feature'] + result.outArgs['invalidFeatures']

      if invalid != {} or errors != {} or ask_default != []:
         raise WallabyValidateError(invalid, errors, ask_default)


   def set_use_default_val(self, name):
      self.params[name.strip()] = False


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


class Parameter(YAMLObject):
   yaml_tag = u'!Parameter'
   def __init__(self, name, type='', default='', desc='', change=True, level=0, restart=False, depends=[], conflicts=[]):
      self.name = name
      self.type = str(type)
      self.default = str(default)
      self.description = str(desc)
      self.must_change = change
      self.level = level
      self.restart = restart
      self.depends = list(depends)
      self.conflicts = list(conflicts)


   def get_name(self):
      return self.name


   def __repr__(self):
      return '%s(name=%r, type=%r, default_value=%r, description=%r, must_change=%r, expert_level=%r, requires_restart=%r, parameter_dependencies=%r, parameter_conflicts=%r' % (self.__class__.__name__, self.name, self.type, self.default, self.description, self.must_change, self.level, self.restart, self.depends, self.conflicts)


   def dict_as_list(self):
      return [('name',self.name), ('type',self.type), ('default',self.default), ('description',self.description), ('must_change',self.must_change), ('level',self.level), ('restart',self.restart), ('depends',self.depends), ('conflicts',self.conflicts)]


   def init_from_obj(self, obj):
      self.type = str(obj.kind)
      self.default = str(obj.default)
      self.description = str(obj.description)
      self.must_change = obj.must_change
      self.level = obj.visibility_level
      self.restart = obj.requires_restart
      self.depends = list(obj.depends)
      self.conflicts = list(obj.conflicts)


   def store_validate(self, store):
      invalid = {}
      errors = {}

      result = store.checkParameterValidity(self.depends)
      if result.status != 0:
         errors[result.status] = result.text
         invalid['Parameter'] = []
      else:
         if result.outArgs['invalidParameters'] != []:
            invalid['Parameter'] = result.outArgs['invalidParameters']

      result = store.checkParameterValidity(self.conflicts)
      if result.status != 0:
         errors[result.status] = result.text
      else:
         if result.outArgs['invalidParameters'] != []:
            invalid['Parameter'] = invalid['Parameter'] + result.outArgs['invalidParameters']

      if invalid != {} or errors != {}:
         raise WallabyValidateError(invalid, errors)


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No parameter object to update'})

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

      result = obj.setMustChange(self.must_change)
      if result.status != 0:
         errors[result.status] = result.text

      result = obj.setVisibilityLevel(self.level)
      if result.status != 0:
         errors[result.status] = result.text

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


class Group(YAMLObject):
   yaml_tag = u'!Group'
   def __init__(self, name, members=[]):
      self.name = name
      self.members = list(members)


   def get_name(self):
      return self.name


   def __repr__(self):
      return '%s(name=%r, group_membership=%r' % (self.__class__.__name__, self.name, self.members)


   def dict_as_list(self):
      return [('name',self.name), ('members',self.members)]


   def init_from_obj(self, obj):
      self.name = str(obj.name)
      self.members = list(obj.membership)


   def store_validate(self, store):
      invalid = {}
      errors = {}

      result = store.checkNodeValidity(self.members)
      if result.status != 0:
         errors[result.status] = result.text
      else:
         if result.outArgs['invalidNodes'] != []:
            invalid['Node'] = result.outArgs['invalidNodes']

      if invalid != {} or errors != {}:
         raise WallabyValidateError(invalid, errors)


   def update(self, obj, store, session):
      errors = {}
      pre_edit_list = []

      if obj == None:
         raise WallabyError({-1:'No group object to update'})

      pre_edit_list = list(obj.membership)

      for node in self.members:
         node = node.strip()
         should_add = True
         if pre_edit_list != [] and node in pre_edit_list:
            should_add = False
         if should_add == True:
            node_obj = get_node(session, store, node)
            if node_obj != None:
               result = node_obj.modifyMemberships('add', [self.name], {})
               if result.status != 0:
                  errors[result.status] = result.text

      if pre_edit_list != []:
         for node in pre_edit_list:
            node = node.strip()
            if node not in self.members:
               node_obj = get_node(session, store, node)
               if node_obj != None:
                  result = node_obj.modifyMemberships('remove', [self.name], {})
                  if result.status != 0:
                     errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)


class Subsystem(YAMLObject):
   yaml_tag = u'!Subsystem'
   def __init__(self, name, params=[]):
      self.name = name
      self.params = list(params)


   def get_name(self):
      return self.name


   def __repr__(self):
      return '%s(name=%r, affecting_parameters=%r' % (self.__class__.__name__, self.name, self.params)


   def dict_as_list(self):
      return [('name',self.name), ('params',self.params)]


   def init_from_obj(self, obj):
      self.name = obj.name
      self.params = list(obj.params)


   def store_validate(self, store):
      invalid = {}
      errors = {}

      result = store.checkParameterValidity(self.params)
      if result.status != 0:
         errors[result.status] = result.text
      else:
         if result.outArgs['invalidParameters'] != []:
            invalid['Parameter'] = result.outArgs['invalidParameters']

      if invalid != {} or errors != {}:
         raise WallabyValidateError(invalid, errors)


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No subsystem object to update'})

      result = obj.modifyParams('replace', self.params, {})
      if result.status != 0:
          errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)
