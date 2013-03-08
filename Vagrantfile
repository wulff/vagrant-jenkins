Vagrant::Config.run do |config|
  # the base box this environment is built off of
  config.vm.box = 'precise32'

  # the url from where to fetch the base box if it doesn't exist
  config.vm.box_url = 'http://files.vagrantup.com/precise32.box'

  # use puppet to provision packages
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = 'puppet/manifests'
    puppet.manifest_file = 'site.pp'
    puppet.module_path = 'puppet/modules'
  end

  # setup master node
  config.vm.define :master, {:primary => true} do |master|
    # configure network
    master.vm.host_name = 'master.local'
    master.vm.network :hostonly, '33.33.33.10', {:adapter => 2}

    # jenkins likes memory
    master.vm.customize ['modifyvm', :id, '--memory', 512, '--name', 'Vagrant Jenkins - Master']
  end

  # setup static phpqa node
  config.vm.define :phpqa, {:primary => true} do |phpqa|
    # configure network
    phpqa.vm.host_name = 'phpqa.local'
    phpqa.vm.network :hostonly, '33.33.33.11', {:adapter => 2}

    # jenkins likes memory
    phpqa.vm.customize ['modifyvm', :id, '--memory', 512, '--name', 'Vagrant Jenkins - PHP QA']
  end
end
