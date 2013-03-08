# site.pp

import 'nodes'
import 'settings'

# define global paths and file ownership
Exec { path => '/usr/sbin/:/sbin:/usr/bin:/bin' }
File { owner => 'root', group => 'root' }
Ssh_authorized_key { ensure => present }

# create a stage to make sure apt-get update is run before all other tasks
stage { 'requirements': before => Stage['main'] }
stage { 'bootstrap': before => Stage['requirements'] }

class jenkins::bootstrap {
  # we need an updated list of sources before we can apply the configuration
	exec { 'jenkins_apt_update':
		command => '/usr/bin/apt-get update',
	}
}

class jenkins::requirements {
  apt::source { 'jenkins':
    location    => 'http://pkg.jenkins-ci.org/debian',
    release     => '',
    repos       => 'binary/',
    key         => 'D50582E6',
    key_server  => 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key',
    include_src => false,
  }

  apt::source { 'mariadb':
    location    => 'http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu',
    release     => 'precise',
    repos       => 'main',
    key         => '1BB943DB',
    include_src => true,
  }
}
