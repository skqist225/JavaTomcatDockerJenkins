Vagrant.configure('2') do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  if Vagrant.has_plugin? 'vagrant-vbguest'
    config.vbguest.no_install  = true
    config.vbguest.auto_update = false
    config.vbguest.no_remote   = true
  end

  ### DB and tomcat vm  ####
  config.vm.define 'airtnt_app' do |airtnt_app|
    airtnt_app.vm.box = 'geerlingguy/centos7'
    airtnt_app.vm.hostname = 'airtntApp'
    airtnt_app.vm.network 'private_network', ip: '192.168.33.29'
    airtnt_app.vm.provision 'shell', path: 'mysql_tomcat.sh'
    airtnt_app.vm.provider 'virtualbox' do |app|
      app.memory = '1024'
    end
  end

  # ### Nginx VM ###
  #   config.vm.define "nginx_airtnt" do |nginx_airtnt|
  #     nginx_airtnt.vm.box = "ubuntu/xenial64"
  #     nginx_airtnt.vm.hostname = "nginxAirtnt"
  #   nginx_airtnt.vm.network "private_network", ip: "192.168.33.22"
  #   nginx_airtnt.vm.provision "shell", path: "nginx.sh"
  #   end
end
