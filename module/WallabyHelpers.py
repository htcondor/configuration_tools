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
import os
import time
from wallabyclient.exceptions import WallabyHelperError

def get_group(sess, store, name):
   if name != '':
      try:
         if name == '+++DEFAULT':
            result = store.getDefaultGroup()
         else:
            result = store.getGroup({'Name': name})
      except Exception, error:
         raise WallabyHelperError(error)
   else:
      return(None)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to find group "%s" (%d, %s)' % (name, result.status, result.text))
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_feature(sess, store, name):
   if name != '':
      try:
         result = store.getFeature(name)
      except Execption, error:
         raise WallabyHelperError(error)
   else:
      return(None)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to find feature "%s" (%d, %s)' % (name, result.status, result.text))
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_param(sess, store, name):
   if name != '':
      try:
         result = store.getParam(name)
      except Exception, error:
         raise WallabyHelperError(error)
   else:
      return(None)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to find parameter "%s" (%d, %s)' % (name, result.status, result.text))
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_node(sess, store, name):
   obj = []
   if name != '':
      # store.GetNode will create a node object if the give name doesn't exist,
      # so look to see if a node exists to avoid creating one
      try:
         result = store.checkNodeValidity([name])
      except Exception, error:
         raise WallabyHelperError(error)

      if result.status != 0:
         raise WallabyHelperError('Error: Unable to verify node validity')
      else:
         if result.outArgs['invalidNodes'] != []:
            raise WallabyHelperError('Error: Failed to find node "%s"' % name)
         else:
            result = store.getNode(name)
            if result.status != 0:
               raise WallabyHelperError('Error: Failed to get object for node "%s"' % name)
            else:
               try:
                  obj = sess.getObjects(_objectId=result.outArgs['obj'])
               except Exception, error:
                  raise WallabyHelperError(error)

               if obj != []:
                  return(obj[0])
               else:
                  return(None)


def get_subsys(sess, store, name):
   if name != '':
      try:
         result = store.getSubsys(name)
      except Exception, error:
         raise WallabyHelperError(error)
   else:
      return(None)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to find subsystem "%s" (%d, %s)' % (name, result.status, result.text))
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def list_feature_info(sess, store, feature):
   try:
      feat_obj = get_feature(sess, store, feature)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if feat_obj != None:
      print 'Feature "%s":' % feature
      print 'Feature ID: %s' % feat_obj.getIndex()
      print 'Name: %s' % feat_obj.name

      value = feat_obj.params
      print 'Included Parameters:'
      for key in value.keys():
         print '  %s = %s' % (key, value[key])

      print 'Included Features:'
      i = 0
      value = feat_obj.included_features
      for key in value:
         print '  %s: %s' % (i, key)
         i = i + 1

      print 'Conflicts:'
      for key in feat_obj.conflicts:
         print '  %s' % key

      print 'Dependencies:'
      i = 0
      value = feat_obj.depends
      for key in value:
         print '  %s: %s' % (i, key)
         i = i + 1


def list_param_info(sess, store, name):
   try:
      param_obj = get_param(sess, store, name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if param_obj != None:
      print 'Parameter "%s":' % name
      print 'Name: %s' % param_obj.getIndex()
      print 'Type: %s' % param_obj.kind
      if param_obj.must_change == True:
         print 'Default: '
      else:
         print 'Default: %s' % param_obj.default
      print 'Description: %s' % param_obj.description
      print 'MustChange: %s' % param_obj.must_change
      print 'VisibilityLevel: %s' % param_obj.visibility_level
      print 'RequiresRestart: %s' % param_obj.requires_restart

      print 'Dependencies:'
      for key in param_obj.depends:
         print '  %s' % key

      print 'Conflicts:'
      for key in param_obj.conflicts:
         print '  %s' % key


def list_group_info(sess, store, group):
   try:
      group_obj = get_group(sess, store, group)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if group_obj != None:
      if group == '+++DEFAULT':
         group = 'Internal Default Group'
      print 'Group "%s":' % group
      print 'Group ID: %s' % group_obj.getIndex()

      name = group_obj.name
      if name == '+++DEFAULT':
         print 'Name: Internal Default Group'
      else:
         print 'Name: %s' % name

      if name != '+++DEFAULT':
         print 'Members:'
         for key in group_obj.membership:
            print '  %s' % key

      i = 0
      print 'Features (priority: name):'
      for key in group_obj.features:
         print '  %s: %s' % (i, key)
         i = i + 1

      value = group_obj.params
      print 'Parameters:'
      for key in value.keys():
         print '  %s = %s' % (key, value[key])


def list_node_info(sess, store, name):
   try:
      node_obj = get_node(sess, store, name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if node_obj != None:
      print 'Node "%s":' % name
      value = node_obj.last_checkin
      if value == 0:
         print 'Last Check-in Time: Never'
      else:
         print 'Last Check-in Time: %s' % time.ctime(value/1000000)

      value = node_obj.memberships
      print 'Group Memberships:'
      for key in value:
         print '  %s' % key
      print '  Internal Default Group'

      print 'Features Applied:'
      feat_num = 0
      group_list = value
      feature_list = {}
      try:
         id_name = get_id_group_name(node_obj, sess)
      except WallabyHelperError, error:
         print error.error
         id_name = None
         
      if id_name != None:
         try:
            group_obj = get_group(sess, store, id_name)
         except WallabyHelperError, error:
            print error.error
            group_obj = None
         if group_obj != None:
            feature_list = group_obj.features

      group_list += ['+++DEFAULT']
      num = 0
      for name in group_list:
         try:
            group_obj = get_group(sess, store, name)
         except WallabyHelperError, error:
            print error.error
            group_obj = None

         if group_obj != None:
            value = group_obj.features
            for key in value:
               if key not in feature_list:
                  feature_list += [key]

      for name in feature_list:
         print '  %s' % name 

      try:
         result = node_obj.getConfig({})
      except WallabyHelperError, error:
         raise WallabyHelperError('Error: Failed to retrieve configuration (%s)' % error.error)

      if result.status != 0:
         raise WallabyHelperError('Error: Failed to retrieve configuration (%d, %s)' % (result.status, result.text))
      else:
         print 'Configuration:'
         value = result.outArgs['config']
         for key in value.keys():
            print '  %s = %s' % (key, value[key])


def list_subsys_info(sess, store, name):
   try:
      subsys_obj = get_subsys(sess, store, name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if subsys_obj != None:
      print 'Subsystem "%s":' % name
      print 'Included Parameters:'
      for key in subsys_obj.params:
         print '  %s' % key


def add_param(sess, store, name):
   if name != '':
      print 'Adding parameter "%s"' % name
   else:
      return(None)

   try:
      result = store.addParam(name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to add parameter "%s" (%d, %s)' % (name, result.status, result.text))
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def add_feature(sess, store, name):
   # Add the feature to the store
   if name != '':
      print 'Adding feature "%s"' % name
   else:
      return(None)

   try:
      result = store.addFeature(name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to add feature "%s" (%d, %s)' % (name, result.status, result.text))
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def add_group(sess, store, name):
   if name != '':
      print 'Adding Group "%s"' % name
   else:
      return(None)

   try:
      result = store.addExplicitGroup(name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to add group "%s" (%d, %s)' % (name, result.status, result.text))
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def add_node(sess, store, name):
   if name != '':
      print 'Adding node "%s"' % name
   else:
      return(None)

   try:
      result = store.addNode(name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to add node "%s" (%d, %s)' % (name, result.status, result.text))
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def add_subsys(sess, store, name):
   if name != '':
      print 'Adding subsystem "%s"' % name
   else:
      return(None)

   try:
      result = store.addSubsys(name)
   except WallabyHelperError, error:
      raise WallabyHelperError(error.error)

   if result.status != 0:
      raise WallabyHelperError('Error: Failed to add subsystem "%s" (%d, %s)' % (name, result.status, result.text))
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         raise WallabyHelperError(error)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_id_group_name(obj, sess):
   name = None
   idgroup_ref = []

   idgroup = obj.identity_group
   try:
      idgroup_ref = sess.getObjects(_objectId=idgroup)
   except Exception, error:
      raise WallabyHelperError(error)

   if idgroup_ref == []:
      raise WallabyHelperError('Error: Unable to find identity group with id "%s" (%d, %s)' % (idgroup, result.status, result.text))
   else:
      name = idgroup_ref[0].name

   return name
