# -*- mode: ruby -*-
# vi: set ft=ruby :
# (c) 2016 - 2017 Mihai Vultur

Vagrant.require_version '>= 1.8.0'

#-- software versions
CHEFDK_release = '1.2.20'
TERRAFORM_release = '0.11.10'
SHELLCHECK_release =  'v0.4.6'
PACKER_release = '1.3.2'
OPENSTACK_release = '3.17'

####### SCRIPTS
install_BASE = <<SCRIPT
echo "Installing base ..."
yum install -y epel-release redhat-lsb
true
#-- we don't need selinux in dev environments
setenforce 0
sed -i 's#^SELINUX=.*#SELINUX=permissive#g' /etc/selinux/config

#Disable IPV6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo 1>/proc/sys/net/ipv6/conf/all/disable_ipv6
echo "search local" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
mv /etc/hosts /etc/hosts.old
echo "192.168.199.20 node1test" > /etc/hosts
echo "192.168.199.21 node2test" >> /etc/hosts
echo "127.0.0.1 $(cat /etc/hostname)" >> /etc/hosts

#-- fix VM time offset when we suspend the host where the VM is running in
echo "sudo ntpdate pool.ntp.org 2>&1 >/dev/null" >> ~/.bashrc
SCRIPT

install_DEV = <<SCRIPT
echo "Installing DEV ..."
yum install -y tmux mc vim-enhanced git svn patch unzip gcc ruby rubygems curl bash-completion strace telnet bind-utils tcpdump nc traceroute telnet whois wget pwkickstart
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

install_PACKER = <<SCRIPT
echo "Installing Packer ..."
packerDir=/opt/packer
mkdir -p $packerDir
wget --content-dis -k https://releases.hashicorp.com/packer/#{PACKER_release}/packer_#{PACKER_release}_linux_amd64.zip -O /opt/packer_#{PACKER_release}_linux_amd64.zip
unzip -q -o /opt/packer_#{PACKER_release}_linux_amd64.zip -d ${packerDir}
chown -R vagrant:vagrant ${packerDir}
ln -sf ${packerDir}/packer /usr/bin/packer
SCRIPT

install_OPENSTACK = <<SCRIPT
echo "Installing OpenStack Client ..."
yum install -y python-devel python-pip
pip install python-openstackclient==#{OPENSTACK_release}
SCRIPT

install_BASH = <<SCRIPT
echo "Installing Bash Development Environment ..."
shellcheckDir=/opt/shellcheck
mkdir -p $shellcheckDir
wget -k https://github.com/xxmitsu/dev_bin/blob/master/shellcheck-#{SHELLCHECK_release}.linux.x86_64.tar.xz?raw=true -O ${shellcheckDir}/shellcheck-#{SHELLCHECK_release}.linux.x86_64.tar.xz
cd ${shellcheckDir} && tar xxf shellcheck-#{SHELLCHECK_release}.linux.x86_64.tar.xz
chown -R vagrant:vagrant ${shellcheckDir}
ln -sf ${shellcheckDir}/shellcheck-#{SHELLCHECK_release}/shellcheck /usr/bin/shellcheck
SCRIPT

install_ANSIBLE = <<SCRIPT
echo "Installing Ansible Development Environment ..."
yum -y install ansible ansible-doc ansible-lint ansible-review standard-test-roles
SCRIPT

install_ICINGA = <<SCRIPT
echo "Installing Icinga Test Environment ..."
wget https://packages.icinga.com/epel/ICINGA-release.repo -O /etc/yum.repos.d/CINGA-release.repo
#-- prerequisites
yum install -y httpd gcc glibc glibc-common gd gd-devel
#-- dbi
yum install -y mysql mysql-server libdbi libdbi-devel libdbi-drivers libdbi-dbd-mysql
service mysqld start
chkconfig mysqld on

#-- plugins
yum install -y nagios-plugins-nrpe nagios-plugins-all nsca perl-snmp

#-- icinga
yum -y install icinga-1.14.0-0.el6.x86_64 icinga-gui-config-1.14.0-0.el6.x86_64 icinga-idoutils-libdbi-mysql-1.14.0-0.el6.x86_64 icinga-doc-1.14.0-0.el6.x86_64 icinga-gui-1.14.0-0.el6.x86_64 icinga-idoutils-1.14.0-0.el6.x86_64 libwmf libwmf-lite 

#-- postconfig
mkdir -p /dev/shm/icinga/{tmp,checkresults}
chown -R icinga:icinga /dev/shm/icinga/
chmod 777 /dev/shm/icinga/{tmp,checkresults}
echo "CREATE DATABASE IF NOT EXISTS icinga;" | mysql -uroot
echo "GRANT USAGE ON *.* TO 'icinga'@'localhost' IDENTIFIED BY PASSWORD '*F7EA22C777E1A8D2E1F61A2F9EBBD74FF489FF63';" | mysql -uroot
echo "GRANT ALL PRIVILEGES ON icinga.* TO 'icinga'@'localhost' WITH GRANT OPTION;" | mysql -uroot
mysql -uicinga -picinga icinga < /usr/share/doc/icinga-idoutils-libdbi-mysql-1.14.0/db/mysql/mysql.sql

#-- start
chkconfig icinga on
chkconfig httpd on
chkconfig ido2db on
service ido2db restart
service icinga restart
service httpd restart
SCRIPT


### VMs
VIRTUAL_MACHINES = {
  workstation: {
    vm_box: 'centos/7',
    hostname: 'workstation.local.lo',
    cpus: 4,
    memory: 2048,
    private_ip: '192.168.199.30',
    environment: 'DevOps',
    shell_script: [ 
      install_BASE,
      install_DEV,
      install_TERRAFORM,
      install_PACKER,
      install_ANSIBLE,
      install_OPENSTACK,
      install_BASH,
      install_DOCKER
    ]
  },
  node2test: {
    vm_box: 'centos/7',
    hostname: 'node2test.local.lo',
    cpus: 2,
    memory: 1024,
    private_ip: '192.168.199.21',
    environment: 'DevOps',
    shell_script: [
      install_BASE,
      install_DEV,
      install_ANSIBLE
    ]
  },
  icinga2test: {
    vm_box: 'centos/6',
    hostname: 'icinga2test.local.lo',
    cpus: 1,
    memory: 1024,
    private_ip: '192.168.199.22',
    environment: 'DevOps',
    shell_script: [
      install_BASE,
      install_DEV,
      install_ICINGA
    ]
  },
  centos7test: {
    vm_box: 'centos/7',
    hostname: 'centos7test.local.lo',
    cpus: 2,
    memory: 1000,
    private_ip: '192.168.199.23',
    environment: 'DevOps',
    shell_script: [
      install_BASE,
      install_DEV
    ]
  },

}.freeze

#-- prerequisites
required_plugins = %w( vagrant-vbguest )
if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil then
	#-- nfs sharing
	required_plugins.push('vagrant-winnfsd')
end

required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

Vagrant.configure(2) do |config|
  #  config.omnibus.chef_version = '12.8.1'
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  VIRTUAL_MACHINES.each do |name, cfg|
    config.vm.box = cfg[:vm_box]
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
