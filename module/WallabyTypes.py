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


def print_wallaby_types(data):
   def key_function((key,value)):
      # Prioritize name when sorting.
      prio = {'name':0, 'type':1, 'default':2, 'description':3, 'params':4}.get(key,99)
      return (prio, key)
   items = data.dict_as_list()
   items.sort(key=key_function)
   return items


class WallabyBaseObject(YAMLObject):
   def __init__(self, name):
      self.name = name
      WallabyBaseObject.init_internal_vars(self)


   def init_internal_vars(self):
      self.invalid = {}


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
      WallabyBaseObject.__init__(self, str(obj.name))
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
         if self.params[param] == None:
            self.params[param] = ''
         else:
            self.params[param] = str(self.params[param])
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      errors = {}
      ask_default = []

      self.invalid['Parameter'] = []
      if self.params != None and isinstance(self.params, dict):
         result = store.checkParameterValidity(self.params.keys())
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               self.invalid['Parameter'] = result.outArgs['invalidParameters']

         for p in self.params.keys():
            if self.params[p] != None and \
               isinstance(self.params[p], str) and \
               self.params[p].strip() == '':
               ask_default += [p]

      self.invalid['Feature'] = []
      if self.includes != None and isinstance(self.includes, list):
         result = store.checkFeatureValidity(self.includes)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidFeatures'] != []:
               self.invalid['Feature'] = result.outArgs['invalidFeatures']

      if self.conflicts != None and isinstance(self.conflicts, list):
         result = store.checkFeatureValidity(self.conflicts)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidFeatures'] != []:
               self.invalid['Feature'] = self.invalid['Feature'] + result.outArgs['invalidFeatures']

      if self.depends != None and isinstance(self.depends, list):
         result = store.checkFeatureValidity(self.depends)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidFeatures'] != []:
               self.invalid['Feature'] = self.invalid['Feature'] + result.outArgs['invalidFeatures']

      if self.invalid != {} or errors != {} or ask_default != []:
         raise WallabyValidateError(self.invalid, errors, ask_default)


   def set_use_default_val(self, name):
      self.params[name.strip()] = 0


   def remove_invalids(self):
      for key in self.invalid.keys():
         for item in self.invalid[key]:
            if key == 'Parameter':
               try:
                  del self.params[item]
               except: 
                  pass
            elif key == 'Feature':
               try:
                  while (1):
                     self.includes.remove(item)
               except: 
                  pass
               try:
                  while (1):
                     self.conflicts.remove(item)
               except: 
                  pass
               try:
                  while (1):
                     self.depends.remove(item)
               except: 
                  pass


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
      WallabyBaseObject.__init__(self, str(obj.name))
      self.type = str(obj.kind)
      self.default = str(obj.default)
      self.description = str(obj.description)
      self.must_change = bool(obj.must_change)
      self.level = int(obj.visibility_level)
      self.restart = bool(obj.requires_restart)
      self.depends = list(obj.depends)
      self.conflicts = list(obj.conflicts)


   def validate(self, orig):
      if self.type == None:
         self.type = ''
      else:
         self.type = str(self.type)
      if self.default == None:
         self.default = ''
      else:
         self.default = str(self.default)
      if self.description == None:
         self.description = ''
      else:
         self.description = str(self.description)
      if self.type == None:
         self.must_change = False
      else:
         self.must_change = bool(self.must_change)
      self.restart = bool(self.restart)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      errors = {}

      self.invalid['Parameter'] = []
      if self.depends != None and isinstance(self.depends, list):
         result = store.checkParameterValidity(self.depends)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               self.invalid['Parameter'] = result.outArgs['invalidParameters']

      if self.conflicts != None and isinstance(self.conflicts, list):
         result = store.checkParameterValidity(self.conflicts)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               self.invalid['Parameter'] = self.invalid['Parameter'] + result.outArgs['invalidParameters']

      if self.invalid != {} or errors != {}:
         raise WallabyValidateError(self.invalid, errors, [])


   def remove_invalids(self):
      for key in self.invalid.keys():
         for item in self.invalid[key]:
            try:
               while (1):
                  self.conflicts.remove(item)
            except: 
               pass
            try:
               while (1):
                  self.depends.remove(item)
            except: 
               pass


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No parameter object to update'})

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
      WallabyBaseObject.__init__(self, str(obj.name))
      self.memberships = list(obj.memberships)


   def validate(self, orig):
      self.name = str(self.name)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      errors = {}

      if self.memberships != None and isinstance(self.memberships, list):
         result = store.checkGroupValidity(self.memberships)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidGroups'] != []:
               self.invalid['Group'] = result.outArgs['invalidGroups']

      if self.invalid != {} or errors != {}:
         raise WallabyValidateError(self.invalid, errors, [])


   def remove_invalids(self):
      for key in self.invalid.keys():
         for item in self.invalid[key]:
            try:
               while (1):
                  self.memberships.remove(item)
            except:
               pass


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
      WallabyBaseObject.__init__(self, str(obj.name))
      self.params = list(obj.params)


   def validate(self, orig):
      self.name = str(self.name)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      errors = {}

      if self.params != None and isinstance(self.params, list):
         result = store.checkParameterValidity(self.params)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               self.invalid['Parameter'] = result.outArgs['invalidParameters']

      if self.invalid != {} or errors != {}:
         raise WallabyValidateError(self.invalid, errors, [])


   def remove_invalids(self):
      for key in self.invalid.keys():
         for item in self.invalid[key]:
            try:
               while (1):
                  self.params.remove(item)
            except:
               pass


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No subsystem object to update'})

      result = obj.modifyParams('replace', self.params, {})
      if result.status != 0:
          errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)

class Group(WallabyBaseObject):
   yaml_tag = u'!Group'
   def __init__(self, name, features=[], params={}):
      if name == '+++DEFAULT':
         name = 'Internal Default Group'
      WallabyBaseObject.__init__(self, str(name))
      self.features = list(features)
      self.params = dict(params)


   def __repr__(self):
      return '%s(name=%r, features=%s, parameters=%r' % (self.__class__.__name__, self.name, self.features, self.params)


   def dict_as_list(self):
      return [('name',self.name), ('features', self.features), ('params',self.params)]


   def init_from_obj(self, obj):
      if obj.name == '+++DEFAULT':
         n = 'Internal Default Group'
      else:
         n = str(obj.name)
      WallabyBaseObject.__init__(self, n)
      self.features = list(obj.features)
      self.params = dict(obj.params)


   def validate(self, orig):
      self.name = str(self.name)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      errors = {}

      if self.features != None and isinstance(self.params, dict):
         result = store.checkFeatureValidity(keys(self.params))
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidFeatures'] != []:
               self.invalid['Feature'] = result.outArgs['invalidFeatures']

      if self.params != None and isinstance(self.params, list):
         result = store.checkParameterValidity(self.params)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidParameters'] != []:
               self.invalid['Parameter'] = result.outArgs['invalidParameters']

      if self.invalid != {} or errors != {}:
         raise WallabyValidateError(self.invalid, errors, [])


   def remove_invalids(self):
      for key in self.invalid.keys():
         for item in self.invalid[key]:
            if key == 'Parameter':
               try:
                  del self.params[item]
               except: 
                  pass
            elif key == 'Feature':
               try:
                  while (1):
                     self.features.remove(item)
               except: 
                  pass


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No subsystem object to update'})

      result = obj.modifyFeatures('replace', self.features, {})
      if result.status != 0:
          errors[result.status] = result.text

      result = obj.modifyParams('replace', self.params, {})
      if result.status != 0:
          errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)


class GroupMembership(WallabyBaseObject):
   yaml_tag = u'!Group'
   def __init__(self, name, store, session, members=[]):
      WallabyBaseObject.__init__(self, str(name))
      self.members = list(members)
      self.orig_members = self.members
      self.store = store
      self.session = session


   def __repr__(self):
      return '%s(name=%r, members=%s)' % (self.__class__.__name__, self.name, self.members)


   def dict_as_list(self):
      return [('name',self.name), ('members', self.members)]


   def init_from_obj(self, obj):
      WallabyBaseObject.__init__(self, str(obj.name))
      result = obj.membership()
      if result.status != 0:
         # TODO: Raise an error?
         pass
      else:
         self.members = list(result.outArgs['nodes'])
         self.orig_members = self.members


   def init_internal_vars(self):
      self.orig_members = self.members
      self.store = None
      self.session = None
      WallabyBaseObject.init_internal_vars(self)


   def set_internal_vars(self, old_members, store, session):
      self.store = store
      self.session = session
      self.orig_members = old_members


   def validate(self, orig):
      self.name = str(self.name)
      WallabyBaseObject.validate(self, orig)


   def store_validate(self, store):
      errors = {}

      if self.members != None and isinstance(self.members, list):
         result = store.checkNodeValidity(self.members)
         if result.status != 0:
            errors[result.status] = result.text
         else:
            if result.outArgs['invalidNodes'] != []:
               self.invalid['Node'] = result.outArgs['invalidNodes']

      if self.invalid != {} or errors != {}:
         raise WallabyValidateError(self.invalid, errors, [])


   def remove_invalids(self):
      for key in self.invalid.keys():
         for item in self.invalid[key]:
            try:
               while (1):
                  self.members.remove(item)
            except: 
               pass


   def update(self, obj):
      errors = {}

      if obj == None:
         raise WallabyError({-1:'No group object to update'})

      for node in self.members:
         if node not in self.orig_members:
            # Node was added
            node = get_node(self.session, self.store, node)
            if node != None:
               result = node.modifyMemberships('add', [self.name], {})
               if result.status != 0:
                  errors[result.status] = result.text

      for node in self.orig_members:
         if node not in self.members:
            # Node was removed
            node = get_node(self.session, self.store, node)
            if node != None:
               result = node.modifyMemberships('remove', [self.name], {})
               if result.status != 0:
                  errors[result.status] = result.text

      if errors != {}:
         raise WallabyError(errors)
