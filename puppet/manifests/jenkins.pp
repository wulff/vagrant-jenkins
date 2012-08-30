# basic site manifest

# define global paths and file ownership
Exec { path => '/usr/sbin/:/sbin:/usr/bin:/bin' }
File { owner => 'root', group => 'root' }

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
  # install git-core and add some useful aliases
  class { 'git': }

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

class jenkins::install {

  # install and configure php

  class { 'php': }

  php::module { 'curl': }
  php::module { 'gd': }
  php::module { 'sqlite': }

  class { 'php::pear': } -> class { 'php::qatools': }

  # install drush

  php::pear::package { 'Console_Table': }

  php::pear::package { 'drush':
    repository => 'pear.drush.org',
    version    => latest,
  }

  # install and configure jenkins

  class { 'jenkins': }

  jenkins::job { 'drupal-template':
    repository => 'git://github.com/wulff/jenkins-drupal-template.git',
  }
  jenkins::job { 'selenium-template':
    repository => 'git://github.com/wulff/jenkins-selenium-template.git',
  }

  jenkins::plugin { 'analysis-core': }
  jenkins::plugin { 'checkstyle': }
  jenkins::plugin { 'dry': }
  jenkins::plugin { 'phing': }
  jenkins::plugin { 'plot': }
  jenkins::plugin { 'pmd': }
  jenkins::plugin { 'build-timeout': }
  jenkins::plugin { 'claim': }
  jenkins::plugin { 'disk-usage': }
  jenkins::plugin { 'email-ext': }
  jenkins::plugin { 'favorite': }
  jenkins::plugin { 'git': }
  jenkins::plugin { 'envinject': }
  jenkins::plugin { 'jobConfigHistory': }
  jenkins::plugin { 'project-stats-plugin': }
  jenkins::plugin { 'redmine': }
  jenkins::plugin { 'seleniumhq': }
  jenkins::plugin { 'statusmonitor': }
  jenkins::plugin { 'instant-messaging': }
  jenkins::plugin { 'jabber': }
  jenkins::plugin { 'tasks': }
  jenkins::plugin { 'warnings': }
  jenkins::plugin { 'greenballs': }
  jenkins::plugin { 'xvfb': }

  # install postfix to make it possible for jenkins to notify via mail

  package { 'postfix':
    ensure => present,
  }

  service { 'postfix':
    ensure  => running,
    require => Package['postfix'],
  }

  # install apache and add a proxy for jenkins

  class { 'apache': }
  apache::mod { 'php5': }
  apache::mod { 'rewrite': }

  apache::vhost::proxy { 'jenkins.33.33.33.10.xip.io':
    priority => '20',
    port     => '80',
    dest     => 'http://localhost:8080',
  }

  # install mariadb and setup a database for jenkins to use

  class { 'mysql::server':
    # use the mysql module to install the mariadb packages
    package_name     => 'mariadb-server',
    # necessary because /sbin/status doesn't know about mysql on ubuntu
    service_provider => 'debian',
  }

  php::module { 'mysqlnd':
    restart => Service['apache2'],
  }

  # install selenium, firefox and xvfb for headless testing

  # virtual framebuffer for running selenium tests using a headless firefox
  package { ['xvfb', 'x11-apps', 'xfonts-100dpi', 'xfonts-75dpi', 'xfonts-scalable', 'xfonts-cyrillic']:
    ensure => present,
  }

  package { 'firefox':
    ensure  => present,
    require => Package['xvfb'],
  }
}

class jenkins::go {
  class { 'jenkins::bootstrap':
    stage => 'bootstrap',
  }
  class { 'apt':
    stage => 'requirements',
  }
  class { 'jenkins::requirements':
    stage => 'requirements',
  }
  class { 'jenkins::install': }
}

include jenkins::go