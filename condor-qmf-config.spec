%{!?python_sitelib: %define python_sitelib %(%{__python} -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")}
%define rel 0.1

Name: condor-qmf-config
Summary: Condor configuration over QMF
Version: 2.0
Release: %{rel}%{?dist}
License: ASL 2.0
URL: http://www.redhat.com/mrg
Source0: %{name}-%{version}-%{rel}.tar.gz
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

%description
The Condor QMF Config package provides a means to quickly and easily
configure machines running Condor by providing tools to define configurations
and apply them to nodes over QMF.

%package client
Summary: Condor QMF Configuration Client
Group: Applications/System
Requires: condor
Requires: python >= 2.3
Requires: python-qpid
Requires: python-condor-job-hooks-common
Requires: python-%{name}-common
Obsoletes: condor-remote-configuration

%description client
The Condor QMF Configuration package provides a means to quickly and easily
configure machines running Condor by providing tools to define configurations
and apply them to nodes over QMF.

This package provides the tools needed for managed clients

%if 0%{?rhel} != 4
%package tools
Summary: Condor QMF Configuration Tools
Group: Applications/System
Requires: python >= 2.4
Requires: python-qpid
Requires: python-%{name}-common
Obsoletes: condor-remote-configuration-server

%description tools
The Condor QMF Configuration package provides a means to quickly and easily
configure machines running Condor by providing tools to define configurations
and apply them to nodes over QMF.

This package provides tools to configure condor pools and the
configuration store
%endif

%package -n python-%{name}-common
Summary: Common functions for condor qmf configuration
Group: Applications/System
Requires: python >= 2.3

%description -n python-%{name}-common
Common function used by MRG condor qmf configuration

%prep
%setup -q

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{python_sitelib}/condorqmfconfig
mkdir -p %{buildroot}/%_sbindir
mkdir -p %{buildroot}/%_var/lib/condor/config
%if 0%{?rhel} != 4
cp -f condor_configure_pool %{buildroot}/%_sbindir
cp -f condor_configure_store %{buildroot}/%_sbindir
%endif
cp -f condor_config_eventd %{buildroot}/%_sbindir
cp -f qmf_config_eventd %{buildroot}/%_var/lib/condor/config
cp -f config_utils.py %{buildroot}/%{python_sitelib}/condorqmfconfig
touch %{buildroot}/%{python_sitelib}/condorqmfconfig/__init__.py

%files client
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%defattr(0755,root,root,-)
%_sbindir/condor_config_eventd
%defattr(0644,condor,condor,-)
%_var/lib/condor/config/qmf_config_eventd

%if 0%{?rhel} != 4
%files tools
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%defattr(0755,root,root,-)
%_sbindir/condor_configure_store
%_sbindir/condor_configure_pool
%endif

%files -n python-%{name}-common
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%{python_sitelib}/condorqmfconfig/config_utils.py*
%{python_sitelib}/condorqmfconfig/__init__.py*

%changelog
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