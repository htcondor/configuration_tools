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

class condor::condor {
   include condor_pkg
   include condor_plugins
   include sesame
   file { "/var/lib/condor/condor_config.local":
          source => "puppet:///condor/configs/$node_name",
          owner => root,
          group => root,
          mode => 644,
          ensure => file,
          require => Package["condor"]
   }
}
