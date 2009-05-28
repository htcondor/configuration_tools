%define rel 16

Summary: Condor Remote Configuration Client Tools
Name: condor-remote-configuration
Version: 1.0
Release: %{rel}%{?dist}
License: ASL 2.0
Group: Applications/System
URL: http://www.redhat.com/mrg
Source0: %{name}-%{version}-%{rel}.tar.gz
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch
Requires: puppet >= 0.24.6
Requires: facter >= 1.5.2-2

%description
The Condor Remote Configuration package provides a means to quickly and easily
configure machines running Condor by providing sensible defaults for different
features.  The condor nodes will need to be running puppet clients for this
package to work.

This package provides configuration files for clients that will need to
be tailored depending on where the server package is installed.

%if 0%{?rhel} != 4
%package server
Summary: Condor Remote Configuration Server Tools
Group: Applications/System
Requires: puppet-server >= 0.24.6
Requires: facter >= 1.5.2-2
Requires: python >= 2.4
Requires: perl

%description server
The Condor Remote Configuration package provides a means to quickly and easily
configure machines running Condor by providing sensible defaults for different
features.  The condor nodes will need to be running puppet clients for this
package to work.

This package provides tools and configuration files for the configuration
server.
%endif

%prep
%setup -q

%install
mkdir -p %{buildroot}/%_sbindir
mkdir -p %{buildroot}/%_sysconfdir/puppet/modules
mkdir -p %{buildroot}/%_sysconfdir/opt/grid/examples
%if 0%{?rhel} != 4
cp -rf module/* %{buildroot}/%_sysconfdir/puppet/modules
cp -f condor_configure_node %{buildroot}/%_sbindir
cp -f condor_node %{buildroot}/%_sbindir
%endif
cp -f config/* %{buildroot}/%_sysconfdir/opt/grid/examples
%if 0%{?rhel} == 4
rm -f %{buildroot}/%_sysconfdir/opt/grid/examples/puppet.conf.master
%endif

%files
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%config(noreplace) %_sysconfdir/opt/grid/examples/puppet.conf.client
%config(noreplace) %_sysconfdir/opt/grid/examples/namespaceauth.conf

%if 0%{?rhel} != 4
%files server
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%defattr(0444,root,root,-)
%config(noreplace) %_sysconfdir/opt/grid/examples/puppet.conf.master
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/common_createddl.sql
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_dedicated_preemption
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_job_router
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_dedicated_scheduler
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_low_latency
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_collector
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_dynamic_provisioning
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_negotiator
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_config.local
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_EC2
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_viewserver
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_credd
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_triggerd
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/pgsql_createddl.sql
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/condor_dbmsd
%config(noreplace) %_sysconfdir/puppet/modules/condor/files/postgresql.conf
%config(noreplace) %_sysconfdir/puppet/modules/condor/manifests/init.pp
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/carod_conf
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_EC2_enhanced
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_startd
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_central_manager
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_ha_central_manager
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/job-hooks_conf
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_common
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_ha_scheduler
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/pg_hba_conf
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_concurrency_limits
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_quill
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/pgpass
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_dedicated_resource
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/condor_scheduler
%config(noreplace) %_sysconfdir/puppet/modules/condor/templates/sesame.conf
%defattr(0755,root,root,-)
%_sysconfdir/puppet/modules/condor/files/condor_add_db_user.pl
%_sysconfdir/puppet/modules/condor/files/condor_generate_config.sh
%_sysconfdir/puppet/modules/condor/files/condor_insert_schema.pl
%_sbindir/condor_configure_node
%_sbindir/condor_node
%endif

%changelog
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
