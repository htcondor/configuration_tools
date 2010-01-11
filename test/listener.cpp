#include "qpid/console/ConsoleListener.h"
#include "qpid/console/SessionManager.h"
#include <qpid/management/Manageable.h>
#include <qpid/management/ManagementObject.h>
#include <qpid/agent/ManagementAgent.h>
#include "qmf/mrg/grid/config/Package.h"

#include <signal.h>
#include <unistd.h>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <map>

using namespace std;
using namespace qpid::console;
using namespace qpid::framing;
using namespace qmf::mrg::grid::config;
using qpid::management::ManagementAgent;
using qpid::management::ManagementObject;
using qpid::management::Manageable;
using qpid::management::Args;

namespace _qmf = qmf::mrg::grid::config;

class EventListener : public ConsoleListener {
    SessionManager* sm;
    Broker* broker;
    ManagementAgent* agent;

public:
   EventListener(const char* host, int port);
   ~EventListener();

       void brokerConnected(const Broker& broker) {
        cout << "brokerConnected: " << broker << endl;
    }

    void brokerDisconnected(const Broker& broker) {
        cout << "brokerDisconnected: " << broker << endl;
    }

    void newPackage(const std::string& name) {
        cout << "newPackage: " << name << endl;
    }

    void newClass(const ClassKey& classKey) {
        cout << "newClass: key=" << classKey << endl;
    }

    void newAgent(const Agent& agent) {
        cout << "newAgent: " << agent << endl;
    }

    void delAgent(const Agent& agent) {
        cout << "delAgent: " << agent << endl;
    }

    void objectProps(Broker& broker, Object& object) {
        cout << "objectProps: broker=" << broker << " object=" << object << endl;
    }
        void objectStats(Broker& broker, Object& object) {
        cout << "objectStats: broker=" << broker << " object=" << object << endl;
    }

    void event(Event& event) {
       cout << "event: " << event << endl;
    }
};

EventListener::EventListener(const char* host, int port)
{
   qpid::client::ConnectionSettings settings;
   SessionManager::Settings sm_settings;

   settings.host = host;
   settings.port = port;
   settings.username = "guest";
   settings.password = "guest";

   sm_settings.rcvObjects = false;
   sm_settings.rcvEvents = true;
   sm_settings.rcvHeartbeats = false;
   sm_settings.userBindings = false;

   sm = new SessionManager(this, sm_settings);
   broker = sm->addBroker(settings);
}

EventListener::~EventListener()
{
   if (broker != NULL)
   {
      sm->delBroker(broker);
      broker = NULL;
   }
   if (sm != NULL)
   {
      delete sm;
      sm = NULL;
   }
}

int main(int argc, char** argv)
{
   EventListener listener("127.0.0.1", 5672);

   while (1)
   {
      sleep(1);
   }
}
