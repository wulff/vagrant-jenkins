# basic site manifest

# define global paths and file ownership
Exec { path => '/usr/sbin/:/sbin:/usr/bin:/bin' }
File { owner => 'root', group => 'root' }

# create a stage to make sure apt-get update is run before all other tasks
stage { 'requirements': before => Stage['main'] }

class jenkins::requirements {
	exec { 'jenkins_apt_update':
		command => '/usr/bin/apt-get update',
	}
}

class jenkins::install {
  # install git-core and add some useful aliases
  class { 'git': }

  # install and configure php

  class { 'php': }

  php::module { 'curl': }
  php::module { 'gd': }
  php::module { 'sqlite': }

  class { 'php::pear': } -> class { 'php::qatools': }

  # virtual framebuffer for running selenium tests using a headless firefox
  package { ['xvfb', 'x11-apps', 'xfonts-100dpi', 'xfonts-75dpi', 'xfonts-scalable', 'xfonts-cyrillic']:
    ensure => present,
  }
}

class jenkins::go {
  class { 'jenkins::requirements':
    stage => 'requirements',
  }
  class { 'jenkins::install': }
}

include jenkins::go