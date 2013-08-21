# == Class: selenium
#
# This class installs the standalone Selenium server and a virtual frame
# buffer.
#
# === Examples
#
#   class { 'selenium': }
#
class selenium {
  file {
    ['/opt/selenium-server', '/usr/local/lib/selenium']:
      ensure => directory,
  }

  package { 'xvfb':
    ensure => latest,
  }

  exec { 'download-selenium':
    command => 'wget -P /opt/selenium-server http://selenium.googlecode.com/files/selenium-server-standalone-2.35.0.jar',
    creates => '/opt/selenium-server/selenium-server-standalone-2.35.0.jar',
    require => File['/opt/selenium-server'];
  }

  exec { 'symlink-selenium':
    command => 'ln -s /opt/selenium-server/selenium-server-standalone-2.35.0.jar selenium-server.jar',
    cwd     => '/usr/local/lib/selenium',
    creates => '/usr/local/lib/selenium/selenium-server.jar',
    require => [File['/usr/local/lib/selenium'], Exec['download-selenium']];
  }
}
