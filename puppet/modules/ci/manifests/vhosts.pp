#
#
#
# http://httpd.apache.org/docs/2.2/vhosts/mass.html
# http://httpd.apache.org/docs/2.2/mod/mod_vhost_alias.html
#
class ci::vhosts () {

  file { '/etc/apache2/conf.d/vhosts.conf':
    source  => 'puppet:///modules/ci/vhosts.conf',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }
  
}
