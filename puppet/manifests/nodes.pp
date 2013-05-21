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

  package { 'htop':
    ensure => present,
  }

  package { 'ncdu':
    ensure => present,
  }

  # TODO: use puppet munin module
  # package { 'munin-node':
  #   ensure => present,
  # }

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
  jenkins::plugin { 'view-job-filters': }
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
      {
        name => 'drupal.peytz.dk',
        description => 'A slave optimized for running Drupal simpletests.',
        labels => 'drupal',
        host => '33.33.33.12',
        port => '22',
        path => '/home/jenkins/ci',
        username => 'jenkins',
        privatekey => '/var/lib/jenkins/.ssh/id_rsa',
        executors => 2,
      },
    ],
    notify => Service['jenkins'],
  }

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

  # use apache as a proxy for jenkins

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
  jenkins::job { 'template-drupal-static-analysis':
    repository => 'git://github.com/wulff/jenkins-template-drupal-static-analysis.git',
    branch => 'develop',
  }

}

node "phpqa.local" inherits "jenkins-slave" {

  package { 'unzip':
    ensure => present,
  }

  package { 'npm':
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

  # install jshint

  exec { 'npm-install-jshint':
    command => 'npm install -g jshint',
    creates => '/usr/local/bin/jshint',
    require => Package['npm'],
  }

  exec { 'npm-update-jshint':
    command => 'npm update -g jshint',
    require => Exec['npm-install-jshint'],
  }

  # install csslint

  exec { 'npm-install-csslint':
    command => 'npm install -g csslint',
    creates => '/usr/local/bin/csslint',
    require => Package['npm'],
  }

  exec { 'npm-update-csslint':
    command => 'npm update -g csslint',
    require => Exec['npm-install-csslint'],
  }

  # download and install phing phploc integration
  # TODO: test whether the phploc task included with phing works as intended

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

  # TODO: add a git pull to make sure the ruleset is up to date

  file { '/usr/share/php/PHP/CodeSniffer/Standards/Drupal':
    ensure => link,
    target => '/opt/coder/coder_sniffer/Drupal',
    require => [Exec['install-drupal-coder'], Class['php::qatools']],
  }

}

node "drupal.local" inherits "jenkins-slave" {

  class { 'jenkins::requirements':
    stage => 'requirements',
  }

  # configure a php-enabled apache server

  class { 'apache': }
  class { 'php': }
  apache::mod { 'php5': }
  apache::mod { 'rewrite': }
  apache::mod { 'vhost_alias': }

  php::pear::package { 'phing':
    repository => 'pear.phing.info',
  }

  class { 'ci::vhosts': }

  # TODO: Add dynamic vhost for /home/jenkins/ci/<jobname>/workspace
  #       http://httpd.apache.org/docs/2.2/vhosts/mass.html

  php::module { 'mysqlnd':
    restart => Service['apache2'],
    require => Class['mysql::server'],
  }

  # install the database server

  class { 'mysql::server':
    # FIXME: this doesn't seem to work with the latest 12.04 LTS
    #        see https://lists.launchpad.net/maria-discuss/msg00698.html
    # use the mysql module to install the mariadb packages
    # package_name     => 'mariadb-server',
    config_hash      => { 'root_password' => 'root' },
    # necessary because /sbin/status doesn't know about mysql on ubuntu
    service_provider => 'debian',
  }

  # add a drush task to phing

  file { '/usr/share/php/phing/tasks/drupal':
    ensure  => directory,
    require => Package["pear-pear.phing.info-phing"],
  }

  exec { 'download-phing-drush-task':
    command => 'wget https://raw.github.com/kasperg/phing-drush-task/master/DrushTask.php',
    cwd     => '/usr/share/php/phing/tasks/drupal',
    creates => '/usr/share/php/phing/tasks/drupal/DrushTask.php',
    require => File['/usr/share/php/phing/tasks/drupal'],
  }

}
