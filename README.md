Vagrant Jenkins
===============

This Vagrantfile and the included puppet manifests can be used to setup a Jenkins server for doing automated testing of Drupal and other PHP-based projects.


Installation
------------

Follow these steps to get a continuous integration environment running on your local machine:

1. Download and install Vagrant: http://vagrantup.com/
2. Clone this repository using the `--recursive` flag (to get the submodules).
3. Go to the root of the repository and run `vagrant up`. Building the virtual machine takes approximately thirty minutes.

To install this environment on a set of phsyical or virtual machines, simply use the puppet manifests included in this repository.


Getting started
---------------

When the virtual machine has booted, you can access the Jenkins instance at the following URL:

    http://33.33.33.10/

No authentication methods are enabled by default, so you won't be asked for a username and password (this is to make local testing and development as easy as possible). If you choose to deploy this setup, you should enable some form of user authentication (Go to *Manage Jenkins* and follow the *Setup Security* wizard).


Configuring jobs
----------------

### Static analysis

To create a new static analysis job, go to the front page and follow the *New Job* link. Enter a descriptive name for your job and select *Copy existing job*. Enter `template-drupal-static-analysis` as the job to copy from.

On the configuration page, you should modify a few settings:

* **Discard Old Builds** Unless you have unlimited disk space, you should tell Jenkins to discard data from old builds. Keeping build data for a couple of weeks is a good starting point.
* **Disable Build** Uncheck this to make sure your job can be run as soon as you are done configuring it.
* **Restrict where this project can be run** We need to make sure that this job runs on a slave which is equipped to run it. In this case, tell Jenkins to always run this job on `phpqa.peytz.dk`.

The static analysis job needs some code to analyze, so we will select *Git* in the *Source Code Management* section and enter the repository URL and branch of the code we wish to analyze.

For our test job, we'll use the `7.x-1.x` branch of the `http://git.drupal.org/project/admin_language.git` repository.

Click the *Save* button at the bottom of the page to save the job configuration.

When the job has been saved, you will be redirected to the job dashboard. Click the *Build Now* link in the sidebar to run the job. When the job has run, you can click the link in the *Build History* sidebar to see the results of the run.

### Selenium

Before you can create a Selenium job, you need to configure the virtual framebuffer which makes it possible to run the browsers *headless*. Go to *Manage Jenkins* and choose *Configure System*. In the *Xvfb installation* section, click the *Add Xvfb installation*, and create an installation with the name `Default` and the path `/usr/bin`.

Now, to create a new Selenium job, go to the front page and follow the *New Job* link. Enter a descriptive name for your job and select *Copy existing job*. Enter `template-selenium` as the job to copy from.

On the configuration page, you should modify a few settings:

* **Discard Old Builds** Unless you have unlimited disk space, you should tell Jenkins to discard data from old builds. Keeping build data for a couple of weeks is a good starting point.
* **Disable Build** Uncheck this to make sure your job can be run as soon as you are done configuring it.
* **Restrict where this project can be run** We need to make sure that this job runs on a slave which is equipped to run it. In this case, tell Jenkins to always run this job on `selenium.peytz.dk`.

The Selenium job needs some test cases to run, so we will select *Git* in the *Source Code Management* section and enter the repository URL and branch of a repository containing some Selenium tests.

For our test job, we'll use the `master` branch of the `https://github.com/wulff/jenkins-demo-selenium.git` repository.

Next, click the *Advanced* button below the *Start Xvfb before the build* option, and make sure that the Xvfb installation, which you just create, has been selected.

Click the *Save* button at the bottom of the page to save the job configuration.

When the job has been saved, you will be redirected to the job dashboard. Click the *Build Now* link in the sidebar to run the job. When the job has run, you can click the link in the *Build History* sidebar to see the results of the run.


Puppet manifests
----------------

The Puppet manifests in this repository have been divided into various classes to make them easier to maintain and extend. The following list gives an overview of the class structure.

* **basenode** The root class makes sure all dependencies have been taken care of, and installs some useful tools.
    * **jenkins-master** Configures a generic Jenkins master server with a selection of plugins. Also, it adds information about the available slaves and adds a SSH key for the jenkins user.
        * **master.local** Configures the master server. Adds a mail server and a proxy for Jenkins, as well as a selection of job templates.
    * **jenkins-slave** Configures a generic Jenkins slave server with a basic JDK setup and the necessary SSH keys to interact with the master.
        * **phpqa.local** Configures a slave server for doing static analysis of PHP code.
        * **drupal.local** Configures a slave server for running Drupal simpletests.
        * **selenium.local** Configures a slave for running Selenium tests using PHPUnit.


Further reading
---------------

* http://www.mabishu.com/blog/2012/04/17/setting-up-jenkins-in-ubuntu-precise-12-04-for-php-projects/
* http://david.ragingnexus.com/blog/2012/04/26/notes-php-qa-tools-jenkins-php-project-template/
