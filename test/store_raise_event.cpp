#include <qpid/management/Manageable.h>
#include <qpid/management/ManagementObject.h>
#include <qpid/agent/ManagementAgent.h>
#include "qmf/mrg/grid/config/EventWallabyConfigEvent.h"
#include "qmf/mrg/grid/config/Package.h"
#include "qpid/framing/FieldTable.h"

#include <signal.h>
#include <unistd.h>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <map>

using namespace std;
using namespace qmf::mrg::grid::config;
using namespace qpid::framing;
using qpid::management::ManagementAgent;
using qpid::management::ManagementObject;
using qpid::management::Manageable;
using qpid::management::Args;

namespace _qmf = qmf::mrg::grid::config;

int main(int argc, char** argv)
{
   /* ARG1 = nodename
      ARG2 = True/False (restart condor)
      ARG3 = condor subsystem
   */
   const string nodes = argv[1];
   bool restart;
   FieldTable subsys;

   const char* host = "127.0.0.1";
   int port = 5672;
   qpid::client::ConnectionSettings settings;
   ManagementAgent::Singleton* singleton = new ManagementAgent::Singleton();

   settings.host = host;
   settings.port = port;
   settings.username = "guest";
   settings.password = "guest";

   ManagementAgent* agent = singleton->getInstance();
   _qmf::Package packageInit(agent);
   agent->init(settings, 1, false, ".magentdata");

   subsys.clear();
   subsys.setString("condor", argv[3]);
   if (strncasecmp (argv[2], "true", strlen(argv[2])) == 0)
   {
      restart = true;
   }
   else
   {
      restart = false;
   }

   EventWallabyConfigEvent event(nodes, restart, subsys);
   event.registerSelf(agent);
   sleep(10);
   agent->raiseEvent(event);

}
