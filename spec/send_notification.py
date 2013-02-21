#!/usr/bin/python

from qpid.messaging import *
import socket

broker = "127.0.0.1:5672"
address = "amq.fanout"

connection = Connection(broker)

try:
  connection.open()
  session = connection.session()

  content = {"nodes": socket.gethostname(), "version": "a1b2c3d4e5f6g7h8"}
  sender = session.sender(address)
  sender.send(Message(content=content))
except MessagingError,m:
  print m
finally:
  connection.close()
