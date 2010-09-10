%{!?python_sitelib: %define python_sitelib %(%{__python} -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")}
%define rel 1
%define ver 3.6

Name: condor-wallaby
Summary: Condor configuration using wallaby
Version: %{ver}
Release: %{rel}%{?dist}
Group: Applications/System
License: ASL 2.0
URL: http://git.fedorahosted.org/git/grid/configuration-tools.git
Source0: %{name}-%{version}-%{rel}.tar.gz
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch
BuildRequires: python >= 2.3

%description
The Condor QMF Config package provides a means to quickly and easily
configure machines running Condor by providing tools to define configurations
and apply them to nodes using wallaby.

%package client
Summary: Wallaby configuration client for condor
Group: Applications/System
Requires: condor >= 7.4.4-0.9
Requires: python >= 2.3
Requires: python-qmf >= 0.7.946106-9
Requires: python-condorutils >= 1.4-3
Obsoletes: condor-remote-configuration

%description client
This package provides a means to quickly and easily configure machines
running Condor by providing tools to define configurations in wallaby and
apply them to nodes.

This package provides the tools needed for managed clients

%if 0%{?rhel} != 4
%package tools
Summary: Wallaby configuration tools for configuring condor
Group: Applications/System
Requires: python >= 2.4
Requires: python-qmf >= 0.7.946106
Requires: python-wallabyclient = %{ver}
Requires: PyYAML
Obsoletes: condor-remote-configuration-server

%description tools
This package provides a means to quickly and easily configure machines
running Condor by providing tools to define configurations in wallaby and
apply them to nodes.

This package provides tools to configure condor pools and wallaby
%endif

%package -n python-wallabyclient
Summary: Tools for interacting with wallaby
Group: Applications/System
BuildRequires: python-devel
Requires: python >= 2.3
Requires: python-condorutils >= 1.4-3
Requires: PyYAML

%description -n python-wallabyclient
Tools for interacting with wallaby

%prep
%setup -q

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{python_sitelib}/wallabyclient
mkdir -p %{buildroot}/%_sbindir
mkdir -p %{buildroot}/%_sysconfdir/condor/config.d
%if 0%{?rhel} != 4
cp -f condor_configure_pool %{buildroot}/%_sbindir
cp -f condor_configure_store %{buildroot}/%_sbindir
%endif
cp -f condor_configd %{buildroot}/%_sbindir
cp -f 99configd.config %{buildroot}/%_sysconfdir/condor/config.d
cp -f module/*.py %{buildroot}/%{python_sitelib}/wallabyclient

%files client
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%defattr(0755,root,root,-)
%_sbindir/condor_configd
%defattr(0644,root,root,-)
%_sysconfdir/condor/config.d/99configd.config

%if 0%{?rhel} != 4
%files tools
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt README
%defattr(0755,root,root,-)
%_sbindir/condor_configure_store
%_sbindir/condor_configure_pool
%endif

%files -n python-wallabyclient
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%defattr(0644, root,root,-)
%{python_sitelib}/wallabyclient/WallabyHelpers.py*
%{python_sitelib}/wallabyclient/WallabyTypes.py*
%{python_sitelib}/wallabyclient/__init__.py*
%{python_sitelib}/wallabyclient/exceptions.py*

%changelog
* Fri Sep 10 2010  <rrati@redhat> - 3.6-1
- Faster error commandline error reporting
- Fixed issue with pool tool removing must_change params when it shouldn't
- Added hostname into the log
- Fixed issue installing invalid configuration files.  Uses exponential
  backoff now.
- Batter handling of errors when communicating with the store
- Increased activation timeout to 10 minutes

* Thu Aug 26 2010  <rrati@redhat> - 3.5-1
- Improved reconnection time to the configuration store
- The node checkin method call timeout set to 20 seconds
- Only latest configuration version is processed
- Reduce performance hit when qmf broker is backed up
- must_change params won't display a default value
- Fixed issue changing param from must_change to not being one
- Cast user input strings/booleans

* Wed Aug 11 2010  <rrati@redhat> - 3.4-1
- Updated dependency versions
- Fixed issue in error log message
- Fixed issues with pool param verification
- New configuration file system
- pool command line error cases reported before attempting to contact store

* Tue Aug 03 2010  <rrati@redhat> - 3.3-1
- Added API version check
- Cleaned up some error messages reported from the store

* Tue Jul 27 2010  <rrati@redhat> - 3.2-1
- Store detection performance improvements
- Improved detection of parameters that much be changed
- Fixed multiple additions of unknown entities when using the store tool
- The configd drops perms on linux, sets perms of config file to 664
- Changed wording when asking to use the default value in store tool

* Tue Jul 13 2010  <rrati@redhat> - 3.1-1
- Updated dependency versions 
- Improved error handling
- Added support for broker user/password in configd
- Fixed crash/deadlock issue in the configd
- Group membership is handled as part of a node object, allowing for priorities

* Wed Jun 23 2010  <rrati@redhat> - 3.0-1
- Transitioned to new NodeUpdatedNotice
- Fixed error messages on tool exits
- Initial checkin will restart/reconfig daemons as well as pull config
- Moved some logging to DEBUG level
- Special casing of non-daemoncore daemons
- special casing of SC_DAEMON_LIST
- Minor bug fixes

* Mon Jun 15 2010  <rrati@redhat> - 2.9-0.2
- Fixed issues raising WallabyValidateError event

* Fri Jun 11 2010  <rrati@redhat> - 2.9-0.1
- Changes to event handling

* Thu Jun 10 2010  <rrati@redhat> - 2.8-0.1
- Shutdown/restart fixes in configd on Windows
- Special handling of ConsoleCollector in condor_configure_pool
- API transition: get methods replaced with properties

* Tue Jun 08 2010  <rrati@redhat> - 2.7-0.6
- Fixed issue with configd's default configuration file
- Fixed issue using parameter default values when configuring features with
  condor_configure_store

* Thu Jun 03 2010  <rrati@redhat> - 2.7-0.5
- Fixed an issue with the configd asking for a configuration version when a
  node has never been configured
- If the configd fails to contact the Store or configure itself, it will
  result in the configd exiting
- Only set SIG_QUIT and other signals that would cause a core dump on
  non-win32 OSes
- Cleaned up shutdown cases in configd

* Tue May 25 2010  <rrati@redhat> - 2.7-0.4
- Only events the configd cares about will be received.

* Mon May 24 2010  <rrati@redhat> - 2.7-0.3
- Catch more signals for clean shutdown

* Fri May 21 2010  <rrati@redhat> - 2.7-0.2
- condor_configure_pool will prompt the user to use a value for a param
  set elsewhere in the pool configuration if a must_change param is not
  given a value

* Fri May 21 2010  <rrati@redhat> - 2.7-0.1
- Increased config logging
- Fixed issues with condor security disallowing the configd to
  restart/reconfig condor in some cases
- --schedds and --qmfbroker can now be used in a remove operation
- Improved VMUniverse and EC2E special case handling
- Corrected errors in condor_configure_store help message
- The configd now acts upon the WallabyConfigEvent
- Support for versioned configurations
- condor_configure_store will not allow setting a default value for
  a parameter if the MustChange is True
- Listing default group will not show the Members field anymore
- The configd now checkins in with the store after random wait between 0-10
  seconds instead of waiting another $UPDATE_INTERVAL to do so
- Fixed issue where the config would always be retrieved even if the version
  hadn't changed
- Fixed issues handling user inputed values that contain spaces
- Fixed issues with qmfbroker and schedds options would step on each other
- Improved error handling
- A successful activation will cause an automatic snapshot to be taken
- If an invalid port is given with -o, an error message is printed
- Changed how date is displayed for a node's 'Last Check-in Time'
- Gracefully handle broker/store going away
- Do not perform final checkin when the configd exits
- Poll the node's status before checking configuration versions
- Removed explicit subsystems from Features
- The metadata for a wallaby type is now presented with important
  information first.
- Better handling of unicode strings
- Moved to the com.redhat.grid.config namespace
- Added lock mechanism to prevent preiodic checkin and event config
  retrieval from clashing

* Wed Apr 14 2010  <rrati@redhat> - 2.6-0.5
- Added python-devel dep to python-wallabyclient
- Fixed issue in configd moving new config file across file systems
- Prevent configd from exiting if it is in the middle of installing the
  new configuration file
- Added --take-snapshot to condor_configure_pool
- Fixed syntax error in condor_configure_store when adding nodes from a
  configuration that added nodes the store didn't know about

* Fri Apr  9 2010  <rrati@redhat> - 2.6-0.4
- Logging message cleanup in configd
- Fixed error when applying configuration w/o features supplied on the
  commandline
- Disallowed entering blank name for a saved snapshot
- Removed --fast option

* Thu Apr  8 2010  <rrati@redhat> - 2.6-0.3
- Removed the python-wallabyclient dep from the client package

* Thu Apr  8 2010  <rrati@redhat> - 2.6-0.2
- Added dep for PyYAML

* Thu Apr  8 2010  <rrati@redhat> - 2.6-0.1
- UI revamp.  Metadata is now entered through an editor rather than by being
  prompted.  $EDITOR is used if set, otherwise vi is used.
- Removed utils.py, added new submodules
- Specfile description updates
- The tools package now depends on python-qmf instead of python-qpid
- Updated calls to condorutils.run_cmd
- Updated to new wallaby protocol.  No more fake lists/sets, function
  call renames.

* Wed Mar 31 2010  <rrati@redhat> - 2.5-0.1
- Changed package name to condor-wallaby
- Switched to condorutils & wallabyclient modules

* Tue Mar 09 2010  <rrati@redhat> - 2.4-0.2
- Removed handling of HUP and ALRM signals.

* Tue Mar 09 2010  <rrati@redhat> - 2.4-0.1
- Changed logging method in configd from syslog to native logging to a file
- Updated configuration file to configure logging
- Changed QMF_CONFIG_CHECK_INTERVAL -> QMF_CONFIGD_CHECK_INTERVAL
- Change hostname retrieval method to a more cross platform implementation
- Fixed issue with unconfigured nodes not retrieving configurations from the
  store
- Fixed error laying down configuration file
- Added support for processing warning messages into pool
- Fixed issue with pool prompting for param values when no params have been
  specified on the command line
- Updated API calls for RemoveFeature and RemoveGroup

* Thu Mar 04 2010  <rrati@redhat> - 2.3-0.2
- Fixed revision history dates

* Thu Mar 04 2010  <rrati@redhat> - 2.3-0.1
- Updated to version 2.3

* Wed Feb 24 2010  <rrati@redhat> - 2.2-0.1
- Updated to version 2.2

* Tue Feb 23 2010  <rrati@redhat> - 2.1-0.1
- Updated to version 2.1

* Fri Feb 19 2010  <rrati@redhat> - 2.0-0.3
- Added README to the tools package
- Configurations can now be activated in the store
- Nodes checkin with the store after receiving the configuration
- The eventd check interval wasn't always an integer
- Last Checkin Time is displayed in a more readable format
- Node objects are no longer created in the store if the tools ask about a
  node that doesn't exist
- Fixed detection of which parameters must be asked for when a configuration
  is changed

* Wed Feb 17 2010  <rrati@redhat> - 2.0-0.2
- Fixed issues relating to prompting for params that must be set by the
  user when adding features to groups/nodes
- Fixed issues setting features on groups/nodes
- Fixed issues setting parameters on groups/nodes
- Setting of schedulers and QMF info will no long overwrite other parameters
  on the group/node
- Improved performance and accuracy of determining parameters that the user
  must set

* Mon Feb 08 2010  <rrati@redhat> - 2.0-0.1
- Initial packaging of 2.0, which uses QMF to communicate to a configuration
  store

* Thu Oct 15 2009  <rrati@redhat> - 1.0-22
- Removed triggerd entries from startd configuration

* Fri Oct  9 2009  <rrati@redhat> - 1.0-21
- Configure low-altency through condor_config (BZ527908)

* Wed Oct  6 2009  <rrati@redhat> - 1.0-20
- Remove prompting for VM_VERSION

* Wed Sep 30 2009  <rrati@redhat> - 1.0-19
- Removed prompting for AMQP exchange when configurating low-latency

* Fri Sep 25 2009  <rrati@redhat> - 1.0-18
- Removed DC_DAEMON_LIST definition (BZ525746)
- Moved create of the feature config directory and added better
  error handling (BZ525749)

* Thu Sep 17 2009  <rrati@redhat> - 1.0-17
- Added support for configuring VM universe (BZ491237)
- Removed all files from /opt (BZ493767)
- Removed configuration of Trigger Service (BZ522531)
- Fixed conflict with schedd and startd on same node (BZ495685)
- Correct HA Schedd lock period (BZ496227)
- HA Schedd name is now prompted for (BZ493340)
- Fixed EC2E configuration for use with multiple hook keywords (BZ502879)

* Thu May 28 2009  <rrati@redhat> - 1.0-16
- Triggerd will start correctly (BZ503051)

* Mon Mar  2 2009  <rrati@redhat> - 1.0-15
- Fixed reporting of duplicate HA Schedulers (BZ486484)
- Added configuration of condor trigger service

* Fri Feb 13 2009  <rrati@redhat> - 1.0-14
- Rebuild bump

* Fri Feb 13 2009  <rrati@redhat> - 1.0-13
- Change source tarball name

* Fri Jan 30 2009  <rrati@redhat> - 1.0-12
- Default y/n answers clearly indicated (BZ481584)
- Changed 'collector name' to 'pool description' (BZ481583)
- Provide method to list nodes being managed and node/feature configs (BZ481582)
- Update EC2 Enhanced configuration for BZ480841

* Tue Jan  6 2009  <rrati@redhat> - 1.0-11
- Fix dependency parsing issue when removing features (BZ478894)
- Removed HAD and Replication log levels for HA Central Managers

* Wed Dec 17 2008  <rrati@redhat> - 1.0-10
- Remove shutdown delay for Amazon AMIs in EC2E routes
- Handle unrecognized features

* Thu Dec 11 2008  <rrati@redhat> - 1.0-9
- Allow all nodes administrative rights for themselves
- Add shutdown delay for Amazon AMIs in EC2E routes

* Wed Dec 10 2008  <rrati@redhat> - 1.0-8
- Fixed race condition with EC2E (BZ475865)

* Thu Dec  4 2008  <rrati@redhat> - 1.0-7
- Force FS authentication for the job router
- Change amazon-gahp to amazon_gahp in configs

* Thu Dec  4 2008  <rrati@redhat> - 1.0-6
- Only build the server package if not on EL4
- Moved python and perl deps to server package

* Thu Dec  4 2008  <rrati@redhat> - 1.0-5
- Fixed Low-Latency configuration so only Low-Latency jobs will be acted upon

* Mon Dec  1 2008  <rrati@redhat> - 1.0-4
- Added configuration of sesame
- Added condor-qmf-plugins to packages to be installed

* Tue Nov 25 2008  <rrati@redhat> - 1.0-3
- Corrected missed tool name changes in the README
- Corrected missed dependencies for concurrency_limits and dynamic_provision
- Fixed bug where concurrency_limits were not prompted for
- Changed plugin locations to be relative to $(LIB)
- Fixed configuration problem with dynamic provisioning.  SLOT_TYPE must use
  lowercase letters
- Set default Negotiator Interval to 20 seconds
- Condor reload is used to tell condor to re-read config files
- Added TRANSFERER_LOG to ha_central_manager to avoid core dump
- QMF_BROKER_PORT won't be listed in a config if it is not provided

* Fri Nov  4 2008  <rrati@redhat> - 1.0-2
- Add changelog
- Fixed rpmlint issues
- Fixed puppet version dependency
- Added facter dependency

* Fri Nov  4 2008  <rrati@redhat> - 1.0-1
- Initial packaging
