#!/usr/bin/python

import wallaroo
import socket

connection = wallaroo.client.ConnectionMeta()
data = connection.fetch_json_resource("/meta/sysinfo/%s" % socket.gethostname(), False, default={})
for k in sorted(data.keys()):
  print "%s = %s" % (k, data[k])
