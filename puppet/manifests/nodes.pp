# nodes.pp

node "basenode" {
  class { 'jenkins::bootstrap':
    stage => 'bootstrap',
  }

  class { 'apt':
    stage => 'requirements',
  }
  class { 'git':
    stage => 'requirements',
  }
  class { 'ntp':
    stage => 'requirements',
  }
}

node "jenkins-master" inherits "basenode" {

  class { 'jenkins::requirements':
    stage => 'requirements',
  }

  # install jenkins and all required plugins

  class { 'jenkins': }

  jenkins::plugin { 'analysis-collector': }
  jenkins::plugin { 'analysis-core': }
  jenkins::plugin { 'ansicolor': }
  jenkins::plugin { 'build-timeout': }
  jenkins::plugin { 'checkstyle': }
  jenkins::plugin { 'claim': }
  jenkins::plugin { 'compact-columns': }
  jenkins::plugin { 'console-column-plugin': }
  jenkins::plugin { 'dashboard-view': }
  jenkins::plugin { 'disk-usage': }
  jenkins::plugin { 'dry': }
  jenkins::plugin { 'dynamicparameter': }
  jenkins::plugin { 'email-ext': }
  jenkins::plugin { 'envinject': }
  jenkins::plugin { 'favorite': }
  jenkins::plugin { 'git': }
  jenkins::plugin { 'git-client': }
  jenkins::plugin { 'jenkinswalldisplay': }
  jenkins::plugin { 'jobConfigHistory': }
  jenkins::plugin { 'log-parser': }
  jenkins::plugin { 'multiple-scms': }
  jenkins::plugin { 'performance': }
  jenkins::plugin { 'phing': }
  jenkins::plugin { 'plot': }
  jenkins::plugin { 'pmd': }
  jenkins::plugin { 'project-stats-plugin': }
  jenkins::plugin { 'tasks': }
  jenkins::plugin { 'token-macro': }
  jenkins::plugin { 'warnings': }

  class { 'jenkins::config':
    slaves => [
      {
        name => 'phpqa.peytz.dk',
        description => 'A slave optimized for doing static code analysis of PHP projects.',
        labels => 'phpqa',
        host => '33.33.33.11',
        port => '22',
        path => '/home/jenkins/ci',
        username => 'jenkins',
        privatekey => '/var/lib/jenkins/.ssh/id_rsa',
        executors => 2,
      },
    ],
    notify => Service['jenkins'],
  }

#  user { 'jenkins':
#    name => 'jenkins',
#    home => '/var/lib/jenkins',
#    shell => '/bin/bash',
#    managehome => false,
#    ensure => present,
#    require => Package['jenkins],
#  }

  file { '/var/lib/jenkins/.ssh':
    ensure => directory,
    owner => jenkins,
    group => nogroup,
    mode => 0700,
    require => Package['jenkins'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa':
    content => $ssh_private_key,
    owner => jenkins,
    group => nogroup,
    mode => 0600,
    require => File['/var/lib/jenkins/.ssh'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa.pub':
    content => $ssh_public_key,
    owner => jenkins,
    group => nogroup,
    mode => 0644,
    require => File['/var/lib/jenkins/.ssh'],
  }

  file { '/var/lib/jenkins/.ssh/config':
    content => "UserKnownHostsFile=/dev/null\nStrictHostKeyChecking=no",
    owner => jenkins,
    group => nogroup,
    mode => 0644,
    require => File['/var/lib/jenkins/.ssh'],
  }

}

node "jenkins-slave" inherits "basenode" {

  package { 'openjdk-6-jre':
    ensure => present,
  }

  user { 'jenkins':
    name => 'jenkins',
    shell => '/bin/bash',
    managehome => true,
    ensure => present,
  }

  ssh_authorized_key { 'jenkins':
    user => 'jenkins',
    type => 'ssh-rsa',
    key => $ssh_public_key,
  }

  file { '/home/jenkins/ci':
    ensure => directory,
    owner => 'jenkins',
    group => 'jenkins',
    require => User['jenkins'],
  }

  file { '/home/jenkins/.gitconfig':
    content => "[user]\n  email = jenkins@peytz.dk\n  name = Peytz Jenkins",
    owner => 'jenkins',
    group => 'jenkins',
    require => User['jenkins'],
  }

  # exec { 'jenkins-update-password':
  #   command => 'echo -e "jenkins\njenkins" | passwd jenkins',
  # }

}

node "master.local" inherits "jenkins-master" {

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

  apache::mod { 'rewrite': }

  apache::vhost::proxy { 'master.33.33.33.10.xip.io':
    port => '80',
    dest => 'http://localhost:8080',
  }

  # install various job templates

  jenkins::job { 'template-drupal-profile':
    repository => 'git://github.com/wulff/jenkins-drupal-template.git',
  }
  jenkins::job { 'template-drupal-module':
    repository => 'git://github.com/wulff/jenkins-drupal-module-template.git',
    branch => 'develop',
  }

}

node "phpqa.local" inherits "jenkins-slave" {

  package { 'unzip':
    ensure => present,
  }

  class { 'php': }

  package { 'php-apc': }
  php::module { 'curl': }
  php::module { 'gd': }
  php::module { 'imagick': }
  php::module { 'sqlite': }
  php::module { 'xdebug': }

  # TODO: https://github.com/sebastianbergmann/phpcpd/issues/57
  class { 'php::pear': } -> class { 'php::qatools': }

  # download and install jshint tools
  
  package { 'npm':
    ensure => present,
  }

  exec { 'npm-install-jshint':
    command => 'npm install -g jshint',
    creates => '/usr/local/bin/jshint',
    require => Package['npm'],
  }
  # TODO: add task for keeping jshint up-to-date

  # download and install rhino

  exec { 'download-rhino':
    command => 'wget -P /root http://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R3.zip',
    creates => '/root/rhino1_7R3.zip',
  }

  exec { 'install-rhino':
    command => 'unzip -q rhino1_7R3.zip && mv rhino1_7R3 /opt',
    cwd     => '/root',
    creates => '/opt/rhino1_7R3',
    require => [Package['unzip'], Exec['download-rhino']],
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

  exec { 'install-drupal-coder':
    command => 'git clone --branch 7.x-2.x http://git.drupal.org/project/coder.git /opt/coder',
    creates => '/opt/coder/coder_sniffer/Drupal/ruleset.xml',
  }

  file { '/usr/share/php/PHP/CodeSniffer/Standards/Drupal':
    ensure => link,
    target => '/opt/coder/coder_sniffer/Drupal',
    require => Exec['install-drupal-coder'],
  }

}
