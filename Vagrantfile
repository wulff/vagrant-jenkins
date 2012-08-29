Vagrant::Config.run do |config|
  config.vm.host_name = 'jenkins'

  # the base box this environment is built off of
  config.vm.box = 'precise32'

  # the url from where to fetch the base box if it doesn't exist
  config.vm.box_url = 'http://files.vagrantup.com/precise32.box'

  # attach network adapters
  config.vm.network :hostonly, '33.33.33.10', {:adapter => 2}

  # use puppet to provision packages
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = 'puppet/manifests'
    puppet.manifest_file = 'jenkins.pp'
    puppet.module_path = 'puppet/modules'
  end
end