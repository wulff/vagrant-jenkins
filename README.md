Vagrant Jenkins
===============

This Vagrantfile and the included puppet manifests can be used to setup a Jenkins server for doing automated testing of Drupal projects.


Installation
------------

1. Download and install Vagrant: http://vagrantup.com/
2. Clone this repository using the `--recursive` flag (to get the submodules).
3. Go to the root of the repository and run `vagrant up`. Building the virtual machine takes approximately twenty minutes.


Getting started
---------------

When the virtual machine has booted, you can access the Jenkins instance at the following URL:

    http://jenkins.33.33.33.10.xip.io/


Author
------

Morten Wulff  
<wulff@ratatosk.net>
