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


   def init_from_obj(self, obj):
      result = obj.getParams()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         # We've got unicode in the map, so remove it.  This is painful
         self.params = dict(result.outArgs['params'])
         for key in self.params.keys():
            val = str(self.params[key])
            del self.params[key]
            self.params[str(key)] = val

      result = obj.getFeatures()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.includes = list(result.outArgs['features'])

      result = obj.getConflicts()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.conflicts = list(result.outArgs['conflicts'])

      result = obj.getDepends()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.depends = list(result.outArgs['depends'])


   def store_validate(self, store):
      invalid = {}
      errors = {}

      result = store.checkParameterValidity(self.params.keys())
      if result.status != 0:
         errors[result.status] = result.text
      else:
         if result.outArgs['invalidParameters'] != []:
            invalid['Parameter'] = result.outArgs['invalidParameters']

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


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No feature object to update'})

      result = obj.modifyParams('replace', self.params, {})
      if result.status != 0:
          errors[result.status] = result.text

      result = obj.modifyFeatures('replace', self.includes, {})
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


   def __repr__(self):
      return '%s(name=%r, type=%r, default_value=%r, description=%r, must_change=%r, expert_level=%r, requires_restart=%r, parameter_dependencies=%r, parameter_conflicts=%r' % (self.__class__.__name__, self.name, self.type, self.default, self.description, self.must_change, self.level, self.restart, self.depends, self.conflicts)


   def init_from_obj(self, obj):
      result = obj.getType()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.type = str(result.outArgs['type'])

      result = obj.getDefault()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.default = str(result.outArgs['default'])

      result = obj.getDescription()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.description = str(result.outArgs['description'])

      result = obj.getDefaultMustChange()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.must_change = result.outArgs['mustChange']

      result = obj.getVisibilityLevel()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.level = result.outArgs['level']

      result = obj.getRequiresRestart()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.restart = result.outArgs['needsRestart']

      result = obj.getDepends()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.depends = list(result.outArgs['depends'])

      result = obj.getConflicts()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.conflicts = list(result.outArgs['conflicts'])


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

      result = obj.setType(self.type)
      if result.status != 0:
         errors[result.status] = result.text

      if self.must_change == False:
         result = obj.setDefault(self.default)
         if result.status != 0:
            errors[result.status] = result.text

      result = obj.setDescription(self.description)
      if result.status != 0:
         errors[result.status] = result.text

      result = obj.setDefaultMustChange(self.must_change)
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


   def __repr__(self):
      return '%s(name=%r, group_membership=%r' % (self.__class__.__name__, self.name, self.members)


   def init_from_obj(self, obj):
      result = obj.getMembership()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.members = list(result.outArgs['nodes'])


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

      result = obj.getMembership()
      if result.status != 0:
         errors[result.status] = result.text
      else:
         pre_edit_list = list(result.outArgs['nodes'])

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


   def __repr__(self):
      return '%s(name=%r, affecting_parameters=%r' % (self.__class__.__name__, self.name, self.params)


   def init_from_obj(self, obj):
      result = obj.getParams()
      if result.status != 0:
         raise WallabyError({result.status:result.text})
      else:
         self.params = list(result.outArgs['params'])


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
