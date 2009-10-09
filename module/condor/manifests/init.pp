$feature_config_dir = "/var/lib/condor/feature_configs"

define condortemplate($owner = root, $group = root, $mode = 644, $content,
                      $backup = false, $recurse = false, $ensure = file) {

   file { $name:
          mode => $mode,
          owner => $owner,
          group => $group,
          backup => $backup,
          recurse => $recurse,
          ensure => $ensure,
          content => $content,
          notify => Service["condor"],
          require => [ Package["condor"], File["$feature_config_dir"],
                       File["/var/lib/condor/condor_config.local"] ]
   }
}

define condorfile($owner = root, $group = root, $mode = 644, $source,
                  $backup = false, $recurse = false, $ensure = file) {

   file { $name:
          mode => $mode,
          owner => $owner,
          group => $group,
          backup => $backup,
          recurse => $recurse,
          ensure => $ensure,
          notify => Service["condor"],
          source => "puppet:///condor/$source",
          require => [ Package["condor"], File["$feature_config_dir"],
                       File["/var/lib/condor/condor_config.local"] ]
   }
}

class condor::condor_feature_dir {
   file { "$feature_config_dir": 
          owner => root,
          group => root,
          mode => 644,
          ensure => directory,
          require => Package["condor"];
   }
}

class condor::condor_generate_config {
   file { "/usr/sbin/condor_generate_config.sh":
          source => "puppet:///condor/condor_generate_config.sh",
          owner => root,
          group => root,
          mode => 755,
          ensure => file,
          notify => Service["condor"],
          require => Package["condor"]
   }
}

class condor::condor_quillwriter_pw {
   file { "/var/lib/condor/spool/.pgpass":
          content => template("condor/pgpass"),
          owner => condor,
          group => condor,
          mode => 440,
          ensure => file,
          require => Package["condor"]
   }
}

class condor::condor_pkg {
   package { condor:
      ensure => installed
   }
}

class condor::condor_plugins {
   package { condor-qmf-plugins:
      ensure => installed
   }
}

class condor::sesame {
   package { sesame:
      ensure => installed
   }
   file { "/etc/sesame/sesame.conf":
          owner => root,
          group => root,
          mode => 644,
          ensure => file,
          require => Package["sesame"],
          content => template("condor/sesame.conf"),
          notify => Service["sesame"]
   }
   service { sesame:
             enable => true,
             ensure => running,
             hasrestart => true,
             restart => "/etc/init.d/condor reload",
             subscribe => File["/etc/sesame/sesame.conf"]
   }
}

class condor::condor_svc {
   service { condor:
             enable => true,
             ensure => running,
             hasrestart => false,
             restart => "/etc/init.d/condor reload",
             subscribe => [ File["/var/lib/condor/condor_config.local"],
                            File["$feature_config_dir"], Package["condor"] ];
   }
}

class condor::condor_config_local {
   include condor_generate_config
   file { "/var/lib/condor/condor_config.local":
          source => "puppet:///condor/condor_config.local",
          owner => root,
          group => root,
          mode => 644,
          ensure => file,
          require => [ Package["condor"], File["$feature_config_dir"],
                       File["/usr/sbin/condor_generate_config.sh"] ]
   }
}

class condor::condor {
   include condor_pkg
   include condor_plugins
   include condor_feature_dir
   include condor_svc
   include condor_config_local
   include condor_dedicated_resource
   include condor_dedicated_scheduler
   include condor_dedicated_preemption
   include condor_ha_scheduler
   include condor_central_manager
   include condor_ha_central_manager
   include condor_low_latency
   include condor_EC2
   include condor_EC2_enhanced
   include condor_concurrency_limits
   include condor_quill
   include condor_dbmsd
   include condor_viewserver
   include condor_dynamic_provisioning
   include condor_collector
   include condor_credd
   include condor_job_router
   include condor_negotiator
   include condor_scheduler
   include condor_startd
   include condor_vm_universe
   include sesame
   condortemplate { "$feature_config_dir/condor_common":
                    content => template("condor/condor_common"),
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => file
   }
}

class condor::condor_dedicated_resource {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_dedicated_resource":
                    content => $dedicated_resource ? {
                               true => template("condor/condor_dedicated_resource"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $dedicated_resource ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_dedicated_scheduler {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condorfile { "$feature_config_dir/condor_dedicated_scheduler":
                source => "condor_dedicated_scheduler",
                owner => root,
                group => root,
                mode => 644,
                ensure => $dedicated_scheduler ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_dedicated_preemption {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condorfile { "$feature_config_dir/condor_dedicated_preemption":
                source => "condor_dedicated_preemption",
                owner => root,
                group => root,
                mode => 644,
                ensure => $dedicated_preemption ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_ha_scheduler {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_ha_scheduler":
                    content => $ha_scheduler ? {
                               true => template("condor/condor_ha_scheduler"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $ha_scheduler ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_central_manager {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_central_manager":
                    content => $central_manager ? {
                               true => template("condor/condor_central_manager"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $central_manager ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_ha_central_manager {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_ha_central_manager":
                    content => $ha_central_manager ? {
                               true => template("condor/condor_ha_central_manager"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $ha_central_manager ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_low_latency {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_low_latency":
                     content => $low_latency ? {
                                true => template("condor/condor_low_latency"),
                                default => " "
                     },
                     owner => root,
                     group => root,
                     mode => 644,
                     ensure => $low_latency ? {
                               true => file,
                               default => absent
                     }
   }
   if $low_latency {
      package { python-qpid:
                ensure => installed
      }
      package { condor-job-hooks:
                ensure => installed
      }
      package { condor-low-latency:
                ensure => installed,
                require => [ Package["condor"], Package["python-qpid"],
                             Package["condor-job-hooks"] ];
      }
   }
}

class condor::condor_EC2 {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condorfile { "$feature_config_dir/condor_EC2":
                source => "condor_EC2",
                owner => root,
                group => root,
                mode => 644,
                ensure => $ec2 ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_EC2_enhanced {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_EC2_enhanced":
                    content => $ec2e ? {
                               true => template("condor/condor_EC2_enhanced"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $ec2e ? {
                              true => file,
                              default => absent
                    }
   }
   if $ec2e {
      package { python-boto:
                ensure => installed
      }
      package { condor-ec2-enhanced-hooks:
                ensure => installed,
                require => [ Package["condor"], Package["python-boto"] ];
      }
   }
}

class condor::condor_concurrency_limits {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_concurrency_limits":
                    content => $concurrency_limits ? {
                               true => template("condor/condor_concurrency_limits"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $concurrency_limits ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_quill {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   if $quill {
      include condor_quillwriter_pw
   }
   condortemplate { "$feature_config_dir/condor_quill":
                    content => $quill ? {
                               true => template("condor/condor_quill"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $quill ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_dbmsd {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   if $dbmsd {
      include condor_quillwriter_pw
   }
   condorfile { "$feature_config_dir/condor_dbmsd":
                source => "condor_dbmsd",
                owner => root,
                group => root,
                mode => 644,
                ensure => $dbmsd ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::postgresql {
   file { "/var/lib/pgsql/data/postgresql.conf":
          mode => 600,
          owner => postgres,
          group => postgres,
          source => "puppet:///condor/postgresql.conf",
          ensure => $dbserver ? {
                    true => file,
                    default => absent
          },
          require => $dbserver ? {
                     true => [ Package["postgresql-server"], Exec["dbinit"] ],
                     default => Package["postgresql-server"]
          }
   }
   file { "/var/lib/pgsql/data/pg_hba.conf":
          mode => 600,
          owner => postgres,
          group => postgres,
          content => $dbserver ? {
                     true => template("condor/pg_hba_conf"),
                     default => " "
          },
          ensure => $dbserver ? {
                    true => file,
                    default => absent
          },
          require => $dbserver ? {
                     true => [ Package["postgresql-server"], Exec["dbinit"] ],
                     default => Package["postgresql-server"]
          }
   }
   file { "/usr/bin/condor_add_db_user.pl":
          mode => 555,
          owner => root,
          group => root,
          source => "puppet:///condor/condor_add_db_user.pl",
          ensure => $dbserver ? {
                    true => file,
                    default => absent
          }
   }
   file { "/usr/bin/condor_insert_schema.pl":
          mode => 555,
          owner => root,
          group => root,
          source => "puppet:///condor/condor_insert_schema.pl",
          ensure => $dbserver ? {
                    true => file,
                    default => absent
          }
   }
   file { "/var/lib/pgsql/common_createddl.sql":
          mode => 444,
          owner => postgres,
          group => postgres,
          source => "puppet:///condor/common_createddl.sql",
          ensure => $dbserver ? {
                    true => file,
                    default => absent
          },
          require => Package["postgresql-server"]
   }
   file { "/var/lib/pgsql/pgsql_createddl.sql":
          mode => 444,
          owner => postgres,
          group => postgres,
          source => "puppet:///condor/pgsql_createddl.sql",
          ensure => $dbserver ? {
                    true => file,
                    default => absent
          },
          require => Package["postgresql-server"]
   }
   package { postgresql-server:
             ensure => $dbserver ? {
                       true => installed,
                       default => absent,
             }
   }
   package { perl-Expect:
             ensure => $dbserver ? {
                       true => installed,
                       default => absent,
             }
   }
   service { postgresql:
             enable => $dbserver ? {
                       true => true,
                       default => false
             },
             ensure => $dbserver ? {
                       true => running,
                       default => stopped
             },
             hasstatus => true,
             require => Exec["dbinit"],
             subscribe => [ File["/var/lib/pgsql/data/postgresql.conf"],
                            File["/var/lib/pgsql/data/pg_hba.conf"],
                            Package["postgresql-server"] ];
   }
   exec { dbinit:
          command => "/etc/init.d/postgresql initdb",
          user => "root",
          path => "/usr/bin:/bin:/sbin:/usr/sbin",
          onlyif => "test ! -f /var/lib/pgsql/data/PG_VERSION",
          require => Package["postgresql-server"]
   }
   if $dbserver {
      exec { create_quillreader:
             command => "condor_add_db_user.pl quillreader '$qrpw'",
             path => "/usr/bin:/bin",
             user => "postgres",
             onlyif => "su -l postgres -c 'psql -c \"select 1 from pg_roles where rolname = \'quillreader\'\" | grep row | cut -c 2'",
             require => [ Package["perl-Expect"], Service["postgresql"],
                          File["/usr/bin/condor_add_db_user.pl"] ]
      }
      exec { create_quillwriter:
             command => "condor_add_db_user.pl quillwriter '$qwpw'",
             path => "/usr/bin:/bin",
             user => "postgres",
             onlyif => "su -l postgres -c 'psql -c \"select 1 from pg_roles where rolname = \'quillwriter\'\" | grep row | cut -c 2'",
             require => [ Package["perl-Expect"], Service["postgresql"],
                          File["/usr/bin/condor_add_db_user.pl"] ]
      }
      exec { create_db:
             command => "createdb -O quillwriter quill",
             path => "/usr/bin:/bin",
             user => "postgres",
             onlyif => "su -l postgres -c 'psql -l | grep -c quill'",
             require => [ Service["postgresql"], Exec["create_quillwriter"] ];
      }
      exec { condor_prog_lang:
             command => "createlang plpgsql quill",
             path => "/usr/bin:/bin",
             user => "postgres",
             onlyif => "su -l postgres -c 'createlang -l quill | grep -c plpgsql'",
             require => [ Service["postgresql"], Exec["create_db"] ];
      }
      exec { condor_quill_schema:
             command => "condor_insert_schema.pl '$qwpw'",
             path => "/usr/bin:/bin",
             user => "root",
             onlyif => "test ! -f /var/lock/subsys/condor_quill_schema",
             require => [ Service["postgresql"], Exec["condor_prog_lang"],
                          File["/usr/bin/condor_insert_schema.pl"] ];
      }
   }
   else
   {
      exec { "rm -f /var/lock/subsys/condor_quill_schema":
             path => "/bin",
             user => root
      }
   }
}

class condor::condor_viewserver {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   file { "/var/lib/condor/pool_history":
          owner => condor,
          group => condor,
          mode => 755,
          ensure => $viewserver ? {
                    true => directory,
                    default => absent
          },
          force => true
   }
   condorfile { "$feature_config_dir/condor_viewserver":
                source => "condor_viewserver",
                owner => root,
                group => root,
                mode => 644,
                ensure => $viewserver ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_dynamic_provisioning {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condorfile { "$feature_config_dir/condor_dynamic_provisioning":
                source => "condor_dynamic_provisioning",
                owner => root,
                group => root,
                mode => 644,
                ensure => $dynamic_provisioning ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_credd {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   file { "/var/lib/condor/cred_dir":
          owner => condor,
          group => condor,
          mode => 700,
          ensure => $credd ? {
                    true => directory,
                    default => absent
          },
          force => true
   }
   condorfile { "$feature_config_dir/condor_credd":
                source => "condor_viewserver",
                owner => root,
                group => root,
                mode => 644,
                ensure => $credd ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_collector {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condorfile { "$feature_config_dir/condor_collector":
                source => "condor_collector",
                owner => root,
                group => root,
                mode => 644,
                ensure => $collector ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_job_router {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condorfile { "$feature_config_dir/condor_job_router":
                source => "condor_job_router",
                owner => root,
                group => root,
                mode => 644,
                ensure => $job_router ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_negotiator {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condorfile { "$feature_config_dir/condor_negotiator":
                source => "condor_negotiator",
                owner => root,
                group => root,
                mode => 644,
                ensure => $negotiator ? {
                          true => file,
                          default => absent
                }
   }
}

class condor::condor_scheduler {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_scheduler":
                    content => $scheduler ? {
                               true => template("condor/condor_scheduler"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $scheduler ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_startd {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   condortemplate { "$feature_config_dir/condor_startd":
                    content => $startd ? {
                               true => template("condor/condor_startd"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $startd ? {
                              true => file,
                              default => absent
                    }
   }
}

class condor::condor_vm_universe {
   include condor_feature_dir
   include condor_pkg
   include condor_svc
   include condor_config_local
   package { xen:
             ensure => $vmuni ? {
                       true => installed,
                       default => absent,
             }
   }
   condortemplate { "$feature_config_dir/condor_vm_universe":
                    content => $vmuni ? {
                               true => template("condor/condor_vm_universe"),
                               default => " "
                    },
                    owner => root,
                    group => root,
                    mode => 644,
                    ensure => $vmuni ? {
                              true => file,
                              default => absent
                    }
   }
}
