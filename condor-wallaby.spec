%{!?python_sitelib: %define python_sitelib %(%{__python} -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")}
%define rel 0.1

Name: condor-wallaby
Summary: Condor configuration using wallaby
Version: 2.6
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
Requires: condor
Requires: python >= 2.3
Requires: python-qmf
Requires: python-condorutils
Requires: python-wallabyclient
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
Requires: python-qmf
Requires: python-wallabyclient
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
Requires: python >= 2.3
Requires: python-condorutils

%description -n python-wallabyclient
Tools for interacting with wallaby

%prep
%setup -q

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{python_sitelib}/wallabyclient
mkdir -p %{buildroot}/%_sbindir
mkdir -p %{buildroot}/%_var/lib/condor/config
%if 0%{?rhel} != 4
cp -f condor_configure_pool %{buildroot}/%_sbindir
cp -f condor_configure_store %{buildroot}/%_sbindir
%endif
cp -f condor_configd %{buildroot}/%_sbindir
cp -f 99configd.config %{buildroot}/%_var/lib/condor/config
cp -f module/*.py %{buildroot}/%{python_sitelib}/wallabyclient

%files client
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%defattr(0755,root,root,-)
%_sbindir/condor_configd
%defattr(0644,condor,condor,-)
%_var/lib/condor/config/99configd.config

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
