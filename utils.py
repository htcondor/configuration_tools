def get_group(sess, store, name):
   if name != '':
      if name == '+++DEFAULT':
         result = store.GetDefaultGroup()
      else:
         result = store.GetGroup({'Name': name})
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find group "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_feature(sess, store, name):
   if name != '':
      result = store.GetFeature(name)
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find feature "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_param(sess, store, name):
   if name != '':
      result = store.GetParam(name)
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find parameter "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_node(sess, store, name):
   if name != '':
      result = store.GetNode(name)
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find node "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def get_subsys(sess, store, name):
   if name != '':
      result = store.GetSubsys(name)
   else:
      return(None)

   if result.status != 0:
      print 'Error: Failed to find subsystem "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
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
         value = result.outArgs['params']
         print 'Included Parameters:'
         for key in value.keys():
            print '  %s = %s' % (key, value[key])

      result = feat_obj.GetFeatures()
      if result.status != 0:
         print 'Error: Failed to retrieve included Features (%d, %s)' % (result.status, result.txt)
      else:
         print 'Included Features (order: featureName):'
         value = result.outArgs['features']
         order = value.keys()
         order.sort()
         for key in order:
            print '  %s: %s' % (key, value[key])

      result = feat_obj.GetConflicts()
      if result.status != 0:
         print 'Error: Failed to retrieve feature Conflicts (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['conflicts']
         print 'Conflicts:'
         for key in value.keys():
            print '  %s' % key

      result = feat_obj.GetDepends()
      if result.status != 0:
         print 'Error: Failed to retrieve feature Dependencies (%d, %s)' % (result.status, result.txt)
      else:
         print 'Dependencies (order: featureName):'
         value = result.outArgs['depends']
         order = value.keys()
         order.sort()
         for key in order:
            print '  %s: %s' % (key, value[key])

      result = feat_obj.GetSubsys()
      if result.status != 0:
         print 'Error: Failed to retrieve Subsystems (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['subsystems']
         print 'Subsystems:'
         for key in value.keys():
            print '  %s' % key


def list_param_info(sess, store, name):
   param_obj = get_param(sess, store, name)
   if param_obj != None:
      print 'Parameter "%s":' % name
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
   group_obj = get_group(sess, store, group)
   if group_obj != None:
      if group == '+++DEFAULT':
         group = 'Internal Default Group'
      print 'Group "%s":' % group

      value = group_obj.getIndex()
      print 'Group ID: %s' % value

      result = group_obj.GetName()
      if result.status != 0:
         print 'Error: Failed to retrieve group name (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['name']
         if value == '+++DEFAULT':
            value = 'Internal Default Group'
         print 'Name: %s' % value

      result = group_obj.GetMembership()
      if result.status != 0:
         print 'Error: Failed to retrieve group membership (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['nodes']
         print 'Members:'
         for key in value.values():
            print '  %s' % key

      result = group_obj.GetFeatures()
      if result.status != 0:
         print 'Error: Failed to retrieve group features (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['features']
         print 'Features (priority: name):'
         for key in value.keys():
            print '  %s: %s' % (key, value[key])

      result = group_obj.GetParams()
      if result.status != 0:
         print 'Error: Failed to retrieve group parameters (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['params']
         print 'Parameters:'
         for key in value.keys():
            print '  %s = %s' % (key, value[key])


def list_node_info(sess, store, name):
   node_obj = get_node(sess, store, name)
   if node_obj != None:
      print 'Node "%s":' % name
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
         for key in value.values():
            print '  %s' % key

      result = node_obj.GetConfig()
      if result.status != 0:
         print 'Error: Failed to retrieve configuration (%d, %s)' % (result.status, result.txt)
      else:
         print 'Configuration:'
         value = result.outArgs['config']
         for key in value.keys():
            print '  %s = %s' % (key, value[key])


def list_subsys_info(sess, store, name):
   subsys_obj = get_subsys(sess, store, name)
   if subsys_obj != None:
      print 'Subsystem "%s":' % name
      result = subsys_obj.GetParams()
      if result.status != 0:
         print 'Error: Failed to retrieve included Parameters (%d, %s)' % (result.status, result.txt)
      else:
         value = result.outArgs['params']
         print 'Included Parameters:'
         for key in value.keys():
            print '  %s' % key


def add_param(sess, store, name):
   if name != '':
      print 'Adding parameter "%s"' % name
   else:
      return(None)

   result = store.AddParam(name)
   if result.status != 0:
      print 'Error: Failed to add parameter "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
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

   result = store.AddFeature(name)
   if result.status != 0:
      print 'Error: Failed to add feature "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
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

   result = store.AddExplicitGroup(name)
   if result.status != 0:
      print 'Error: Failed to add group "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
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

   result = store.AddNode(name)
   if result.status != 0:
      print 'Error: Failed to add node "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
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

   result = store.AddSubsys(name)
   if result.status != 0:
      print 'Error: Failed to add subsystem "%s" (%d, %s)' % (name, result.status, result.txt)
      return(None)
   else:
      try:
         obj = sess.getObjects(_objectId=result.outArgs['obj'])
      except RuntimeError, error:
         print 'Error: %s' % error
         return(None)

      if obj != []:
         return(obj[0])
      else:
         return(None)


def modify_feature(obj, name, action):
   # Get the information needed for the feature
   if name != '':
      print 'Modifying feature "%s"' % name
   else:
      return

   answer = 'y'
   if action == 'edit':
      answer = raw_input('Modify the parameters included in feature "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetParams()
         if result.status != 0:
            print 'Error: Failed to retrieve current parameter list for feature "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current configured parameters:'
            val = result.outArgs['params']
            list = ''
            for key in val.keys():
               print '%s=%s' % (key, val[key])
   if answer.lower() == 'y':
      print 'List of parameters (blank line ends input):'
      list = {}
      input = raw_input('param=value: ')
      while input != '':
         param = input.split('=', 1)
         if len(param) != 2:
            list[param[0].strip()] = False
         else:
            list[param[0].strip()] = param[1].strip()
         input = raw_input('param=value: ')
      result = obj.ModifyParams('replace', list, {})
      if result.status != 0:
          print 'Error: Failed to modify parameters of feature "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify the list of features included in feature "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetFeatures()
         if result.status != 0:
            print 'Error: Failed to retrieve current feature list for feature "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current configured features:'
            val = result.outArgs['features']
            list = ''
            for key in val.keys():
               print '%s=%s' % (val[key], key)
   if answer.lower() == 'y':
      valid_input = False
      while valid_input == False:
         print 'Feature names this feature will include (blank line ends input):'
         input = raw_input('feature=priority: ')
         pri_list = []
         while input != '':
            pri_list += ['%s' % input]
            input = raw_input('feature=priority: ')
         (valid_input, list) = process_priority_list(pri_list)
      result = obj.ModifyFeatures('replace', list, {})
      if result.status != 0:
         print 'Error: Failed to modify included features for feature "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify the list of features that feature "%s" conflicts with [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetConflicts()
         if result.status != 0:
            print 'Error: Failed to retrieve current list of conflicts for feature "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current configured feature conflicts:'
            val = result.outArgs['conflicts']
            list = ''
            for key in val.keys():
               print '%s' % key
   if answer.lower() == 'y':
      print 'List of feature names this feature conflicts with (blank line ends input):'
      input = raw_input('conflict: ')
      list = {}
      while input != '':
         list[input.strip()] = True
         input = raw_input('conflict: ')
      result = obj.ModifyConflicts('replace', list, {})
      if result.status != 0:
         print 'Error: Failed to modify conflicts of feature "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify the list of features that feature "%s" depends upon [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetDepends()
         if result.status != 0:
            print 'Error: Failed to retrieve current list of dependencies for feature "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current configured feature dependencies:'
            val = result.outArgs['depends']
            list = ''
            for key in val.keys():
               print '%s=%s' % (val[key], key)
   if answer.lower() == 'y':
      valid_input = False
      while valid_input == False:
         print('Feature names this feature depends on (blank line ends input):')
         input = raw_input('feature=priority: ')
         pri_list = []
         while input != '':
            pri_list += ['%s' % input]
            input = raw_input('feature=priority: ')
         (valid_input, list) = process_priority_list(pri_list)
      result = obj.ModifyDepends('replace', list, {})
      if result.status != 0:
         print 'Error: Failed to modify depends of feature "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify the list of subsystems that feature "%s" uses [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetSubsys()
         if result.status != 0:
            print 'Error: Failed to retrieve current list of subsystems for feature "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current configured subsystems:'
            val = result.outArgs['subsystems']
            list = ''
            for key in val.keys():
               print '%s' % key
   if answer.lower() == 'y':
      print('List of subsystems this feature uses (blank line ends input): ')
      input = raw_input('subsystem: ')
      list = {}
      while input != '':
         list[input.strip()] = True
         input = raw_input('subsystem: ')
      result = obj.ModifySubsys('replace', list)
      if result.status != 0:
         print 'Error: Failed to modify subsystem list of feature "%s" (%d, %s)' % (name, result.status, result.txt)


def modify_param(obj, name, action):
   # Get the specifics of the parameter
   if name != '':
      print 'Modifying parameter "%s"' % name
   else:
      return

   answer = 'y'
   if action == 'edit':
      answer = raw_input('Modify the type for parameter "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetType()
         if result.status != 0:
            print 'Error: Failed to retrieve type for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            val = result.outArgs['type']
            print 'Current type: %s' % val
   if answer.lower() == 'y':
      value = raw_input('Type: ')
      result = obj.SetType(value)
      if result.status != 0:
         print 'Error: Failed to modify type of parameter "%s" (%d, %s)' % (name, result.status, result.txt)
   
   if action == 'edit':
      answer = raw_input('Modify the default value for parameter "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetDefault()
         if result.status != 0:
            print 'Error: Failed to retrieve default value for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            val = result.outArgs['default']
            print 'Current default value: %s' % val
   if answer.lower() == 'y':
      value = raw_input('Default Value: ')
      result = obj.SetDefault(value)
      if result.status != 0:
         print 'Error: Failed to modify default value of parameter "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify the description for parameter "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetDescription()
         if result.status != 0:
            print 'Error: Failed to retrieve description for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            val = result.outArgs['description']
            print 'Current description: %s' % val
   if answer.lower() == 'y':
      value = raw_input('Description: ')
      result = obj.SetDescription(value)
      if result.status != 0:
         print 'Error: Failed to modify description of "%s" for parameter "%s" (%d, %s)' % (value, name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify the DefaultMustChange for parameter "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetDefaultMustChange()
         if result.status != 0:
            print 'Error: Failed to retrieve DefaultMustChange for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            val = result.outArgs['mustChange']
            print 'Current DefaultMustChange: %s' % val
   if answer.lower() == 'y':
      value = raw_input('Should this parameter require customization when used [Y/n]? ')
      if value.lower() == 'n':
         result = obj.SetDefaultMustChange(False)
      else:
         result = obj.SetDefaultMustChange(True)
      if result.status != 0:
         print 'Error: Failed to modify DefaultMustChange of parameter "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify the expert level for parameter "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetVisibilityLevel()
         if result.status != 0:
            print 'Error: Failed to retrieve expert level for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            val = result.outArgs['level']
            print 'Current expert level: %s' % val
   if answer.lower() == 'y':
      valid_input = False
      while valid_input == False:
         valid_input = True
         value = raw_input('Expert level [0]: ')
         if value == '':
            value = 0
         else:
            try:
               junk = int(value)
            except ValueError:
               print 'Error: "%s" is not a valid value' % value
               valid_input = False
      result = obj.SetVisibilityLevel(value)
      if result.status != 0:
         print 'Error: Failed to modify expert level of parameter "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify whether changes to parameter "%s" forces a restart [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetRequiresRestart()
         if result.status != 0:
            print 'Error: Failed to retrieve requires restart for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            val = result.outArgs['needsRestart']
            print 'Current requires restart: %s' % val
   if answer.lower() == 'y':
      value = raw_input('Restart condor when this parameter is changed [y/N]? ')
      if value.lower() == 'y':
         result = obj.SetRequiresRestart(True)
      else:
         result = obj.SetRequiresRestart(False)
      if result.status != 0:
         print 'Error: Failed to modify RequiresRestart of parameter "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify parameter dependencies for parameter "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetDepends()
         if result.status != 0:
            print 'Error: Failed to retrieve parameter dependencies for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current parameter dependencies:'
            val = result.outArgs['depends']
            list = ''
            for key in val.keys():
               print '%s' % key
   if answer.lower() == 'y':
      print 'List of parameter names that "%s" depends on (blank line ends input):' % name
      input = raw_input('dependency: ')
      list = {}
      while input != '':
         list[input.strip()] = True
         input = raw_input('dependency: ')
      result = obj.ModifyDepends('replace', list, {})
      if result.status != 0:
         print 'Error: Failed to modify depenecies of parameter "%s" (%d, %s)' % (name, result.status, result.txt)

   if action == 'edit':
      answer = raw_input('Modify parameter conflicts for parameter "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetConflicts()
         if result.status != 0:
            print 'Error: Failed to retrieve parameter conflicts for parameter "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current parameter conflicts:'
            val = result.outArgs['conflicts']
            list = ''
            for key in val.keys():
               print '%s' % key
   if answer.lower() == 'y':
      print 'List of parameter names that "%s" conflicts with (blank line ends input): ' % name
      input = raw_input('conflict: ')
      list = {}
      while input != '':
         list[input.strip()] = True
         input = raw_input('conflict: ')
      result = obj.ModifyConflicts('replace', list, {})
      if result.status != 0:
         print 'Error: Failed to modify conflicts of parameter "%s" (%d, %s)' % (name, result.status, result.txt)


def modify_group(obj, name, action, store, sess):
   if name != '':
      print 'Modifying group "%s"' % name
   else:
      return

   answer = 'y'
   pre_edit_list = ''
   if action == 'edit':
      answer = raw_input('Modify the node membership of group "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetMembership()
         if result.status != 0:
            print 'Error: Failed to retrieve current node membership for group "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current node membership:'
            val = result.outArgs['nodes']
            pre_edit_list = []
            for key in val.keys():
               pre_edit_list += ['%s' % val[key]]
               print val[key]
   if answer.lower() == 'y':
      print 'Names of nodes included in this group (blank line ends input):'
      input = raw_input('included node: ')
      definition = {}
      while input != '':
         definition[input.strip()] = True
         input = raw_input('included node: ')
      for node in definition.keys():
         node = node.strip()
         should_add = True
         if pre_edit_list != '' and node in pre_edit_list:
            should_add = False
         if should_add == True:
            node_obj = get_node(sess, store, node)
            if node_obj != None:
               result = node_obj.ModifyMemberships('add', {'0':name}, {})
               if result.status != 0:
                  print 'Error: Failed to add node "%s" to group "%s" (%d, %s)' % (node, name, result.status, result.txt)

      if pre_edit_list != '':
         for node in pre_edit_list:
            node = node.strip()
            if node not in definition.keys():
               node_obj = get_node(sess, store, node)
               if node_obj != None:
                  result = node_obj.ModifyMemberships('remove', {'0':name}, {})
                  if result.status != 0:
                     print 'Error: Failed to remove node "%s" to group "%s" (%d, %s)' % (node, name, result.status, result.txt)


def modify_subsys(obj, name, action):
   # Get the specifics of the subsystem
   if name != '':
      print 'Modifying subsystem "%s"' % name
   else:
      return

   answer = 'y'
   if action == 'edit':
      answer = raw_input('Modify the parameters included in subsystem "%s" [y/N]? ' % name)
      if answer.lower() == 'y':
         result = obj.GetParams()
         if result.status != 0:
            print 'Error: Failed to retrieve current parameter list for subsystem "%s" (%d, %s)' % (name, result.status, result.txt)
         else:
            print 'Current parameters for the subsystem:'
            val = result.outArgs['params']
            list = ''
            for key in val.keys():
               print '%s' % key
   if answer.lower() == 'y':
      print 'List of parameters affecting subsystem "%s" (blank line ends input):' % name
      input = raw_input('parameter: ')
      list = {}
      while input != '':
         list[input.strip()] = True
         input = raw_input('parameter: ')
      result = obj.ModifyParams('replace', list, {})
      if result.status != 0:
          print 'Error: Failed to modify parameters affecting subsystem "%s" (%d, %s)' % (name, result.status, result.txt)


def process_priority_list(list):
   valid = True
   pairs = {}
   for pair in list:
      if pair != '':
         split = pair.split('=',1)
         if len(split) < 2:
            print 'Error: Invalid input.  "%s" must be assigned a priority' % split[0].strip()
            valid = False
            break
         elif split[1] in pairs:
            print 'Error: The priority "%s" is used twice' % split[1].strip()
            valid = False
            break
         else:
            pairs[split[1].strip()] = split[0].strip()
   return (valid, pairs)
