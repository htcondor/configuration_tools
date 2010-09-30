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

def get_group(sess, store, name):
   if name != '':
      if name == '+++DEFAULT':
         result = store.getDefaultGroup()
      else:
         result = store.getGroup({'Name': name})
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find group "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_feature(sess, store, name):
   if name != '':
      result = store.getFeature(name)
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find feature "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_param(sess, store, name):
   if name != '':
      result = store.getParam(name)
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find parameter "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_node(sess, store, name):
   obj = []
   if name != '':
      # store.GetNode will create a node object if the give name doesn't exist,
      # so look to see if a node exists to avoid creating one
      result = store.checkNodeValidity([name])
      if result.status != 0:
         print 'Error: Unable to verify node validity'
         return(None)
      else:
         if result.outArgs['invalidNodes'] != []:
            print 'Error: Failed to find node "%s"' % name
            return(None)
         else:
            result = store.getNode(name)
            if result.status != 0:
               print 'Error: Failed to get object for node "%s"' % name
               return(None)
            else:
               try:
                  obj = sess.getObjects(_objectId=result.outArgs['obj'])
               except Exception, error:
                  print 'Error: %s' % error
                  return(None)

               if obj != []:
                  return(obj[0])
               else:
                  return(None)


def get_subsys(sess, store, name):
   if name != '':
      result = store.getSubsys(name)
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find subsystem "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def list_feature_info(sess, store, feature):
   feat_obj = get_feature(sess, store, feature)
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
   param_obj = get_param(sess, store, name)
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
   group_obj = get_group(sess, store, group)
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
         members = hasattr(group_obj.membership,'__iter__') and group_obj.membership or group_obj.membership().nodes
         for key in members:
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
   node_obj = get_node(sess, store, name)
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
      id_name = get_id_group_name(node_obj, sess)
      if id_name != None:
         group_obj = get_group(sess, store, id_name)
         if group_obj != None:
            feature_list = group_obj.features

      group_list += ['+++DEFAULT']
      num = 0
      for name in group_list:
         group_obj = get_group(sess, store, name)
         if group_obj != None:
            value = group_obj.features
            for key in value:
               if key not in feature_list:
                  feature_list += [key]

      for name in feature_list:
         print '  %s' % name 

      result = node_obj.getConfig({})
      if result.status != 0:
         print 'Error: Failed to retrieve configuration (%d, %s)' % (result.status, result.text)
      else:
         print 'Configuration:'
         value = result.outArgs['config']
         for key in value.keys():
            print '  %s = %s' % (key, value[key])


def list_subsys_info(sess, store, name):
   subsys_obj = get_subsys(sess, store, name)
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

   result = store.addParam(name)
   if result.status != 0:
      print 'Error: Failed to add parameter "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

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

   result = store.addFeature(name)
   if result.status != 0:
      print 'Error: Failed to add feature "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def add_group(sess, store, name):
   if name != '':
      print 'Adding Group "%s"' % name
   else:
      return(None)

   result = store.addExplicitGroup(name)
   if result.status != 0:
      print 'Error: Failed to add group "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def add_node(sess, store, name):
   if name != '':
      print 'Adding node "%s"' % name
   else:
      return(None)

   result = store.addNode(name)
   if result.status != 0:
      print 'Error: Failed to add node "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def add_subsys(sess, store, name):
   if name != '':
      print 'Adding subsystem "%s"' % name
   else:
      return(None)

   result = store.addSubsys(name)
   if result.status != 0:
      print 'Error: Failed to add subsystem "%s" (%d, %s)' % (name, result.status, result.text)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except Exception, error:
         print 'Error: %s' % error
         return(None)

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
      print 'Error: %s' % error

   if idgroup_ref == []:
      print 'Error: Unable to find identity group with id "%s" (%d, %s)' % (idgroup, result.status, result.text)
   else:
      name = idgroup_ref[0].name

   return name
