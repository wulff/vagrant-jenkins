Puppet module for SeleniumHQ
============================

This module allows you to install the standalone Selenium server package as well as a virtual frame buffer for running headless frontend tests.

Your node-specific manifest is in charge of installing the required browsers (currently Firefox and Chromium are known to work).

Basic usage
-----------

Install Selenium:

    class { 'selenium': }

Authors
-------

Morten Wulff <wulff@peytz.dk>

Copyright
---------

Copyright 2012-2013 [Peytz & Co](http://peytz.dk/)
