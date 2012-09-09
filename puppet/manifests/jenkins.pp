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

  package { 'unzip': }

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

  # install drush and the phing command

  php::pear::package { 'Console_Table': }

  php::pear::package { 'drush':
    repository => 'pear.drush.org',
    version    => latest,
  }

  file { ['/usr/share/drush', '/usr/share/drush/commands']:
    ensure => directory,
  }

  # TODO: remove this, since we're using codesniffer?
  exec { 'dr-drupal-clone-phing':
    command => 'git clone --branch develop git://github.com/wulff/drush-phing.git phing',
    cwd     => '/usr/share/drush/commands',
    creates => '/usr/share/drush/commands/phing/phing.drush.inc',
    require => File['/usr/share/drush/commands'],
  }

  # install and configure jenkins

  class { 'jenkins': }

  jenkins::job { 'drupal-template':
    repository => 'git://github.com/wulff/jenkins-drupal-template.git',
  }
  jenkins::job { 'selenium-template':
    repository => 'git://github.com/wulff/jenkins-selenium-template.git',
  }
  jenkins::job { 'jmeter-template':
    repository => 'git://github.com/wulff/jenkins-jmeter-template.git',
  }

  jenkins::plugin { 'analysis-core': }
  jenkins::plugin { 'build-timeout': }
  jenkins::plugin { 'checkstyle': }
  jenkins::plugin { 'claim': }
  jenkins::plugin { 'disk-usage': }
  jenkins::plugin { 'dry': }
  jenkins::plugin { 'email-ext': }
  jenkins::plugin { 'envinject': }
  jenkins::plugin { 'favorite': }
  jenkins::plugin { 'git': }
  jenkins::plugin { 'instant-messaging': }
  jenkins::plugin { 'jabber': }
  jenkins::plugin { 'jobConfigHistory': }
  jenkins::plugin { 'performance': }
  jenkins::plugin { 'phing': }
  jenkins::plugin { 'plot': }
  jenkins::plugin { 'pmd': }
  jenkins::plugin { 'project-stats-plugin': }
  jenkins::plugin { 'seleniumhq': }
  jenkins::plugin { 'statusmonitor': }
  jenkins::plugin { 'tasks': }
  jenkins::plugin { 'warnings': }
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
  class { 'apache::mod::proxy': }

  apache::mod { 'php5': }
  apache::mod { 'rewrite': }

  apache::vhost::proxy { 'jenkins.33.33.33.10.xip.io':
    port => '80',
    dest => 'http://localhost:8080',
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

  mysql::db { 'drupal_jenkins':
    user     => 'drupal',
    password => 'drupal',
  }

  # install selenium, firefox and xvfb for headless testing

  file { ['/opt/selenium-server', '/usr/local/lib/selenium']:
    ensure => directory,
  }

  exec { 'download-selenium':
    command => 'wget -P /opt/selenium-server http://selenium.googlecode.com/files/selenium-server-standalone-2.25.0.jar',
    creates => '/opt/selenium-server/selenium-server-standalone-2.25.0.jar',
    require => File['/opt/selenium-server'],
  }

  file { '/usr/local/lib/selenium/selenium-server.jar':
    ensure  => link,
    target  => '/opt/selenium-server/selenium-server-standalone-2.25.0.jar',
    require => [File['/usr/local/lib/selenium'], Exec['download-selenium']],
  }

  # virtual framebuffer for running selenium tests using a headless firefox
  package { ['xvfb', 'x11-apps', 'xfonts-100dpi', 'xfonts-75dpi', 'xfonts-scalable', 'xfonts-cyrillic']:
    ensure => present,
  }

  package { 'firefox':
    ensure  => present,
    require => Package['xvfb'],
  }

  # download and install jslint tools

  exec { 'download-jslint4java':
    command => 'wget -P /root https://jslint4java.googlecode.com/files/jslint4java-2.0.2-dist.zip',
    creates => '/root/jslint4java-2.0.2-dist.zip',
  }

  exec { 'install-jslint4java':
    command => 'unzip -q jslint4java-2.0.2-dist.zip && mv jslint4java-2.0.2 /opt && chmod 755 /opt/jslint4java-2.0.2',
    cwd     => '/root',
    creates => '/opt/jslint4java-2.0.2',
    require => Exec['download-jslint4java'],
  }

  file { '/opt/jslint':
    ensure => directory,
  }

  exec { 'download-fulljslint':
    command => 'wget https://raw.github.com/mikewest/JSLint/master/fulljslint.js',
    cwd     => '/opt/jslint',
    creates => '/opt/jslint/fulljslint.js',
    require => File['/opt/jslint'],
  }

  # download and install rhino

  exec { 'download-rhino':
    command => 'wget -P /root http://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R3.zip',
    creates => '/root/rhino1_7R3.zip',
  }

  exec { 'install-rhino':
    command => 'unzip -q rhino1_7R3.zip && mv rhino1_7R3 /opt',
    cwd     => '/root',
    creates => '/opt/rhino1_7R3',
    require => Exec['download-rhino'],
  }

  file { '/opt/csslint':
    ensure => directory,
  }

  exec { 'download-csslint':
    command => 'wget https://raw.github.com/stubbornella/csslint/master/release/csslint-rhino.js',
    cwd     => '/opt/csslint',
    creates => '/opt/csslint/csslint-rhino.js',
    require => File['/opt/csslint'],
  }

  # download and install phing phploc integration

  file { '/opt/phploctask':
    ensure => directory,
  }

  exec { 'download-phploctask':
    command => 'wget https://raw.github.com/raphaelstolt/phploc-phing/master/PHPLocTask.php',
    cwd     => '/opt/phploctask',
    creates => '/opt/phploctask/PHPLocTask.php',
    require => File['/opt/phploctask'],
  }

  # download drupal codesniffer rules

  exec { 'install-drupalcs':
    command => 'wget http://ftp.drupal.org/files/projects/drupalcs-7.x-1.0.tar.gz && tar xzf drupalcs-7.x-1.0.tar.gz && rm drupalcs-7.x-1.0.tar.gz',
    cwd     => '/opt',
    creates => '/opt/drupalcs/Drupal/ruleset.xml',
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
