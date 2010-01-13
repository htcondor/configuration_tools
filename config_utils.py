def get_group(sess, store, name):
#   result = store.GetGroup({'Name': name})
   result = store.GetGroupByName(name)
   if result.status != 0:
      print 'Error: Failed to find group "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      obj = sess.getObjects(_objectId=result.outArgs['obj'])
      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_feature(sess, store, name):
   result = store.GetFeature(name)
   if result.status != 0:
      print 'Error: Failed to find feature "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      obj = sess.getObjects(_objectId=result.outArgs['obj'])
      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_param(sess, store, name):
   result = store.GetParam(name)
   if result.status != 0:
      print 'Error: Failed to find parameter "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      obj = sess.getObjects(_objectId=result.outArgs['obj'])
      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_node(sess, store, name):
   result = store.GetNode(name)
   if result.status != 0:
      print 'Error: Failed to find node "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      obj = sess.getObjects(_objectId=result.outArgs['obj'])
      if obj != []:
         return(obj[0])
      else:
         return(None)


def list_feature_info(sess, store, feature):
   print 'Feature "%s":' % feature
   feat_obj = get_feature(sess, store, feature)
   if feat_obj != None:
      value = feat_obj.getIndex()
      print 'Feature ID: %s' % value

      result = feat_obj.GetName()
      if result.status != 0:
         print 'Error: Failed to retrieve Feature Name (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['name']
         print 'Name: %s' % value

      result = feat_obj.GetParams()
      if result.status != 0:
         print 'Error: Failed to retrieve included Parameters (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['list']
         print 'Included Parameters:'
         for key in value.keys():
            print '%s = %s' % (key, value[key])

      result = feat_obj.GetFeatures()
      if result.status != 0:
         print 'Error: Failed to retrieve included Features (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['list']
         print 'Included Features (featureId, priority):'
         for key in value.keys():
            print '%s, %s' % (key, value[key])

      result = feat_obj.GetConflicts()
      if result.status != 0:
         print 'Error: Failed to retrieve feature Conflicts (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['list']
         print 'Conflicts:'
         for key in value.keys():
            print '%s, %s' % (key, value[key])

      result = feat_obj.GetDepends()
      if result.status != 0:
         print 'Error: Failed to retrieve feature Dependencies (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['list']
         print 'Dependencies (featureId, priority):'
         for key in value.keys():
            print '%s, %s' % (key, value[key])


def list_param_info(sess, store, name):
   print 'Parameter "%s":' % name
   param_obj = get_param(sess, store, name)
   if param_obj != None:
      value = param_obj.getIndex()
      print 'Name: %s' % value

      result = param_obj.GetType()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Type (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['type']
         print 'Type: %s' % value

      result = param_obj.GetDefault()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Default value (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['default']
         print 'Default: %s' % value

      result = param_obj.GetDescription()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Description (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['description']
         print 'Description: %s' % value

      result = param_obj.GetDefaultMustChange()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s MustChange (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['mustChange']
         print 'MustChange: %s' % value

      result = param_obj.GetVisibilityLevel()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Visibility Level (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['level']
         print 'VisibilityLevel: %s' % value

      result = param_obj.GetRequiresRestart()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Requires Restart (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['needsRestart']
         print 'RequiresRestart: %s' % value

      result = param_obj.GetDepends()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Dependencies (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['depends']
         print 'Dependencies:'
         for key in value.keys():
            print '  %s' % key

      result = param_obj.GetConflicts()
      if result.status != 0:
         print 'Error: Failed to retrieve parameter\'s Conflicts (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['conflicts']
         print 'Conflicts:'
         for key in value.keys():
            print '  %s' % key


def list_group_info(sess, store, group):
   print 'Group "%s":' % group
   group_obj = get_group(sess, store, group)
   if group_obj != None:
      value = group_obj.getIndex()
      print 'Feature ID: %s' % value

      result = group_obj.GetName()
      if result.status != 0:
         print 'Error: Failed to retrieve group name (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['name']
         print 'Name: %s' % value

      result = group_obj.GetMembership()
      if result.status != 0:
         print 'Error: Failed to retrieve group membership (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['list']
         print 'Members (priority, hostname):'
         for key in value.keys():
            print '%s, %s' % (key, value[key])

      result = group_obj.GetFeatures()
      if result.status != 0:
         print 'Error: Failed to retrieve group features (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['features']
         print 'Features (name, priority):'
         for key in value.keys():
            print '%s, %s' % (key, value[key])

      result = group_obj.GetParams()
      if result.status != 0:
         print 'Error: Failed to retrieve group parameters (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['params']
         print 'Parameters:'
         for key in value.keys():
            print '%s = %s' % (key, value[key])


def list_node_info(sess, store, name):
   print 'Name: %s' % name
   node_obj = get_node(sess, store, name)
   if node_obj != None:
      result = node_obj.GetPool()
      if result.status != 0:
         print 'Error: Failed to retrieve pool (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['pool']
         print 'Pool: %s' % value

      result = node_obj.GetLastCheckinTime()
      if result.status != 0:
         print 'Error: Failed to retrieve LastCheckinTime (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['time']
         print 'Last Check-in Time: %d' % value

      result = node_obj.GetMemberships()
      if result.status != 0:
         print 'Error: Failed to retrieve group memberships (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['groups']
         print 'Group Memberships:'
         for key in value.keys():
            print key

      result = node_obj.GetConfig()
      if result.status != 0:
         print 'Error: Failed to retrieve configuration (%d, %s)' % (result.status, result.txt)
      else:
         print 'Configuration:'
         value = result.outArgs['config']
         for key in value.keys():
            print '%s = %s' % (key, value[key])
