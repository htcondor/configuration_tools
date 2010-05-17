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
from wallabyclient.exceptions import WallabyError
#from datetime import datetime

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
      value = feat_obj.getIndex()
      print 'Feature ID: %s' % value

      result = feat_obj.getName()
      if result.status != 0:
         print 'Error: Failed to retrieve Feature Name (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['name']
         print 'Name: %s' % value

      result = feat_obj.getParams()
      if result.status != 0:
         print 'Error: Failed to retrieve included Parameters (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['params']
         print 'Included Parameters:'
         for key in value.keys():
            print '  %s = %s' % (key, value[key])

      result = feat_obj.getFeatures()
      if result.status != 0:
         print 'Error: Failed to retrieve included Features (%d, %s)' % (result.status, result.text)
      else:
         print 'Included Features:'
         i = 0
         for key in result.outArgs['features']:
            print '  %s: %s' % (i, key)
            i = i + 1

      result = feat_obj.getConflicts()
      if result.status != 0:
         print 'Error: Failed to retrieve feature Conflicts (%d, %s)' % (result.status, result.text)
      else:
         print 'Conflicts:'
         for key in result.outArgs['conflicts']:
            print '  %s' % key

      result = feat_obj.getDepends()
      if result.status != 0:
         print 'Error: Failed to retrieve feature Dependencies (%d, %s)' % (result.status, result.text)
      else:
         print 'Dependencies (order: featureName):'
         i = 0
         for key in result.outArgs['depends']:
            print '  %s: %s' % (i, key)
            i = i + 1


def list_param_info(sess, store, name):
   param_obj = get_param(sess, store, name)
   if param_obj != None:
      print 'Parameter "%s":' % name
      value = param_obj.getIndex()
      print 'Name: %s' % value

      result = param_obj.getType()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Type (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['type']
         print 'Type: %s' % value

      result = param_obj.getDefault()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Default value (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['default']
         print 'Default: %s' % value

      result = param_obj.getDescription()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Description (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['description']
         print 'Description: %s' % value

      result = param_obj.getDefaultMustChange()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s MustChange (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['mustChange']
         print 'MustChange: %s' % value

      result = param_obj.getVisibilityLevel()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Visibility Level (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['level']
         print 'VisibilityLevel: %s' % value

      result = param_obj.getRequiresRestart()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Requires Restart (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['needsRestart']
         print 'RequiresRestart: %s' % value

      result = param_obj.getDepends()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Dependencies (%d, %s)' % (result.status, result.text)
      else:
         print 'Dependencies:'
         for key in result.outArgs['depends']:
            print '  %s' % key

      result = param_obj.getConflicts()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Conflicts (%d, %s)' % (result.status, result.text)
      else:
         print 'Conflicts:'
         for key in result.outArgs['conflicts']:
            print '  %s' % key


def list_group_info(sess, store, group):
   group_obj = get_group(sess, store, group)
   if group_obj != None:
      if group == '+++DEFAULT':
         group = 'Internal Default Group'
      print 'Group "%s":' % group

      value = group_obj.getIndex()
      print 'Group ID: %s' % value

      result = group_obj.getName()
      name = ''
      if result.status != 0:
         print 'Error: Failed to retrieve group name (%d, %s)' % (result.status, result.text)
      else:
         name = result.outArgs['name']
         if name == '+++DEFAULT':
            print 'Name: Internal Default Group'
         else:
            print 'Name: %s' % name

      if name != '+++DEFAULT':
         result = group_obj.getMembership()
         if result.status != 0:
            print 'Error: Failed to retrieve group membership (%d, %s)' % (result.status, result.text)
         else:
            print 'Members:'
            for key in result.outArgs['nodes']:
               print '  %s' % key

      result = group_obj.getFeatures()
      if result.status != 0:
         print 'Error: Failed to retrieve group features (%d, %s)' % (result.status, result.text)
      else:
         print 'Features (priority: name):'
         i = 0
         for key in result.outArgs['features']:
            print '  %s: %s' % (i, key)
            i = i + 1

      result = group_obj.getParams()
      if result.status != 0:
         print 'Error: Failed to retrieve group parameters (%d, %s)' % (result.status, result.text)
      else:
         value = result.outArgs['params']
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

      result = node_obj.getMemberships()
      if result.status != 0:
         print 'Error: Failed to retrieve group memberships (%d, %s)' % (result.status, result.text)
      else:
         print 'Group Memberships:'
         value = result.outArgs['groups']
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
            result = group_obj.getFeatures()
            if result.status != 0:
               print 'Error: Unable to retrieve node specific features (%d, %s)' % (result.status, result.text)
            else:
               feature_list = result.outArgs['features']

      group_list += ['+++DEFAULT']
      num = 0
      for name in group_list:
         group_obj = get_group(sess, store, name)
         if group_obj != None:
            result = group_obj.getFeatures()
            if result.status != 0:
               print 'Error: Unable to retrieve features for group "%s" (%s, %s)' % (group, result.status, result.text)
            else:
               value = result.outArgs['features']
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
      result = subsys_obj.getParams()
      if result.status != 0:
         print 'Error: Failed to retrieve included Parameters (%d, %s)' % (result.status, result.text)
      else:
         print 'Included Parameters:'
         for key in result.outArgs['params']:
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
      print 'Adding Node "%s"' % name
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

   result = obj.getIdentityGroup()
   if result.status != 0:
      print 'Error: Unable to retrieve the identity group (%d, %s)' % (result.status, result.text)
   else:
      try:
         idgroup_ref = sess.getObjects(_objectId=result.outArgs['group'])
      except Exception, error:
         print 'Error: %s' % error

      if idgroup_ref == []:
         print 'Error: Unable to find identity group with id "%s" (%d, %s)' % (result.outArgs['obj'], result.status, result.text)
      else:
         result = idgroup_ref[0].getName()
         if result.status != 0:
            print 'Error: Unable to retrieve identity group name (5s, %s)' % (result.status, result.text)
         else:
            name = result.outArgs['name']

   return name
