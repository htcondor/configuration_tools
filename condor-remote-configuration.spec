Summary: Condor Remote Configuration Client Tools
Name: condor-remote-configuration
Version: 1.0
Release: 1%{?dist}
License: ASL 2.0
Group: Applications/System
Source0: %{name}-%{version}.tar.gz
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch
Requires: python >= 2.4
Requires: perl
Requires: puppet >= 24.6

%description
The Condor Remote Configuration package provides a means to quickly and easily
configure machines running Condor by providing sensible defaults for different
features.  The condor nodes will need to be running puppet clients for this
package to work.

This package provides configuration files for clients that will need to
be tailored depending on where the server package is installed.

%package server
Summary: Condor Remote Configuration Server Tools
Group: Applications/System
Requires: puppet-server >= 24.6

%description server
The Condor Remote Configuration package provides a means to quickly and easily
configure machines running Condor by providing sensible defaults for different
features.  The condor nodes will need to be running puppet clients for this
package to work.

This package provides tools and configuration files for the configuration
server.

%prep
%setup -q

%install
mkdir -p %{buildroot}/%_sbindir
mkdir -p %{buildroot}/%_sysconfdir/puppet/modules
mkdir -p %{buildroot}/%_sysconfdir/opt/grid/examples
cp -rf module/* %{buildroot}/%_sysconfdir/puppet/modules
cp -f condor_configure_node %{buildroot}/%_sbindir
cp -f condor_node %{buildroot}/%_sbindir
cp -f config/* %{buildroot}/%_sysconfdir/opt/grid/examples

%files
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%_sysconfdir/opt/grid/examples/puppet.conf.client
%_sysconfdir/opt/grid/examples/namespaceauth.conf

%files server
%defattr(-,root,root,-)
%doc LICENSE-2.0.txt
%defattr(0444,root,root,-)
%_sysconfdir/opt/grid/examples/puppet.conf.master
%_sysconfdir/puppet/modules/condor/files/common_createddl.sql
%_sysconfdir/puppet/modules/condor/files/condor_dedicated_preemption
%_sysconfdir/puppet/modules/condor/files/condor_job_router
%_sysconfdir/puppet/modules/condor/files/condor_add_db_user.pl
%_sysconfdir/puppet/modules/condor/files/condor_dedicated_scheduler
%_sysconfdir/puppet/modules/condor/files/condor_low_latency
%_sysconfdir/puppet/modules/condor/files/condor_collector
%_sysconfdir/puppet/modules/condor/files/condor_dynamic_provisioning
%_sysconfdir/puppet/modules/condor/files/condor_negotiator
%_sysconfdir/puppet/modules/condor/files/condor_config.local
%_sysconfdir/puppet/modules/condor/files/condor_EC2
%_sysconfdir/puppet/modules/condor/files/condor_viewserver
%_sysconfdir/puppet/modules/condor/files/condor_credd
%_sysconfdir/puppet/modules/condor/files/condor_generate_config.sh
%_sysconfdir/puppet/modules/condor/files/pgsql_createddl.sql
%_sysconfdir/puppet/modules/condor/files/condor_dbmsd
%_sysconfdir/puppet/modules/condor/files/condor_insert_schema.pl
%_sysconfdir/puppet/modules/condor/files/postgresql.conf
%_sysconfdir/puppet/modules/condor/manifests/init.pp
%_sysconfdir/puppet/modules/condor/templates/carod_conf
%_sysconfdir/puppet/modules/condor/templates/condor_EC2_enhanced
%_sysconfdir/puppet/modules/condor/templates/condor_startd
%_sysconfdir/puppet/modules/condor/templates/condor_central_manager
%_sysconfdir/puppet/modules/condor/templates/condor_ha_central_manager
%_sysconfdir/puppet/modules/condor/templates/job-hooks_conf
%_sysconfdir/puppet/modules/condor/templates/condor_common
%_sysconfdir/puppet/modules/condor/templates/condor_ha_scheduler
%_sysconfdir/puppet/modules/condor/templates/pg_hba_conf
%_sysconfdir/puppet/modules/condor/templates/condor_concurrency_limits
%_sysconfdir/puppet/modules/condor/templates/condor_quill
%_sysconfdir/puppet/modules/condor/templates/pgpass
%_sysconfdir/puppet/modules/condor/templates/condor_dedicated_resource
%_sysconfdir/puppet/modules/condor/templates/condor_scheduler
%defattr(0555,root,root,-)
%_sbindir/condor_configure_node
%_sbindir/condor_node
