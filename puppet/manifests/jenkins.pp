
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

  # necessary hack to make sure selenium uses the firefox binary instead of the
  # shell script to start the browser
  file { '/usr/bin/firefox-bin':
    ensure  => link,
    target  => '/usr/lib/firefox/firefox',
    require => Package['firefox'],
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
