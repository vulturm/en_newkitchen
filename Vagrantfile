# -*- mode: ruby -*-
# vi: set ft=ruby :
# (c) 2016 - 2017 Mihai Vultur

Vagrant.require_version '>= 1.8.0'

#-- software versions
EPEL_release = 'latest'
CHEFDK_release = '1.2.20'
TERRAFORM_release = '0.9.2'

####### SCRIPTS
install_BASE = <<SCRIPT
echo "Installing base ..."
yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-#{EPEL_release}-7.noarch.rpm redhat-lsb
true
#Disable IPV6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo 1>/proc/sys/net/ipv6/conf/all/disable_ipv6
echo "search local" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
mv /etc/hosts /etc/hosts.old
echo "192.168.100.20 node1test" > /etc/hosts
echo "192.168.100.21 node2test" >> /etc/hosts
SCRIPT

install_DEV = <<SCRIPT
echo "Installing DEV ..."
yum install -y mc vim-enhanced git svn patch unzip gcc ruby rubygems curl bash-completion strace telnet bind-utils tcpdump nc traceroute telnet whois
SCRIPT

install_chefDK = <<SCRIPT
echo "Installing ChefDK ..."
yum install -y https://packages.chef.io/files/stable/chefdk/#{CHEFDK_release}/el/7/chefdk-#{CHEFDK_release}-1.el7.x86_64.rpm 
true
SCRIPT

install_DOCKER = <<SCRIPT
echo "Installing Docker ..."
yum install -y docker
echo "DOCKER_NETWORK_OPTIONS='-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock'" | sudo tee /etc/sysconfig/docker-network > /dev/null
sudo systemctl enable docker && sudo systemctl restart docker
echo -e 'export DOCKER_HOST=tcp://127.0.0.1:2375\nunset DOCKER_CERT_PATH\nunset DOCKER_TLS_VERIFY' > /etc/profile.d/docker_TCP.sh
echo -e 'Run:\n  export DOCKER_HOST=tcp://127.0.0.1:2375 && unset DOCKER_CERT_PATH && unset DOCKER_TLS_VERIFY\nto use docker on the host machine'
SCRIPT

install_TERRAFORM = <<SCRIPT
echo "Installing Terraform ..."
terraformDir=/opt/terraform
mkdir -p $terraformDir
wget https://releases.hashicorp.com/terraform/#{TERRAFORM_release}/terraform_#{TERRAFORM_release}_linux_amd64.zip -O /opt/terraform_#{TERRAFORM_release}_linux_amd64.zip
unzip -q -o /opt/terraform_#{TERRAFORM_release}_linux_amd64.zip -d ${terraformDir}
chown -R vagrant:vagrant ${terraformDir}
ln -sf ${terraformDir}/terraform /usr/bin/terraform
SCRIPT


### VMs
VIRTUAL_MACHINES = {
  workstation: {
    hostname: 'workstation.local.lo',
    cpus: 4,
    memory: 4096,
    private_ip: '192.168.100.30',
    environment: 'DevOps',
    shell_script: [ 
      install_BASE,
      install_DEV,
      install_TERRAFORM,
      install_DOCKER
		]
  },
  node2test: {
    hostname: 'node2test.local.lo',
    cpus: 2,
    memory: 1024,
    private_ip: '192.168.100.21',
    environment: 'DevOps',
    shell_script: [
      install_BASE
	]
  },
}.freeze

Vagrant.configure(2) do |config|
  config.vm.box = 'centos/7'
#  config.omnibus.chef_version = '12.8.1'
  config.vbguest.auto_update = false

  VIRTUAL_MACHINES.each do |name, cfg|
    config.vm.define name do |vm_config|
      # private net between
      vm_config.vm.network 'private_network', virtualbox__intnet: 'intnet'
      vm_config.vm.network 'private_network', ip: cfg[:private_ip]
      vm_config.vm.hostname = cfg[:hostname]
      vm_config.vm.synced_folder "shared/#{name}", '/vagrant', create: true, type: :nfs
      vm_config.vm.provider 'virtualbox' do |v|
        v.name = cfg[:hostname]
        v.customize ['modifyvm', :id, '--memory', cfg[:memory]]
        v.customize ['modifyvm', :id, '--cpus', cfg[:cpus]]
        v.customize ['modifyvm', :id, '--paravirtprovider', 'default']
	v.customize ['modifyvm', :id, '--ioapic', 'on']
	v.customize ['modifyvm', :id, '--hwvirtex', 'on']
      end
	  vm_config.vm.provision 'file', source: '~/.ssh/id_rsa.pub', destination: '~/.ssh/xanto.pub'
	  vm_config.vm.provision 'shell', inline: 'cat ~vagrant/.ssh/xanto.pub >> ~vagrant/.ssh/authorized_keys'
	  cfg[:shell_script].each do |provision_with|
		vm_config.vm.provision :shell, :inline => provision_with
	  end
      vm_config.berkshelf.enabled = false if Vagrant.has_plugin?('vagrant-berkshelf')
      if cfg[:forwarded_ports]
        cfg[:forwarded_ports].each do |port|
          vm_config.vm.network 'forwarded_port', guest: port[:guest], host: port[:host]
        end
      end
    end
  end
end 
