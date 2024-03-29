# -*- mode: ruby -*-
# vi: set ft=ruby :
# (c) 2016 - Present Mihai Vultur <xanto@egaming[dot]ro>

Vagrant.require_version '>= 1.8.0'
VAGRANTFILE_API_VERSION = "2"

## HOSTS CONFIGS, Down below..
####### Configs
GLOBAL_CONFIGS = {
  #-- Pin those versions
  software_versions: {
    Chef_DK:            '1.2.20',
    docker_slim:        '1.34.0',
    tfenv:              '1.0.1',
    helm:               '3.1.1',
    k9s:                '0.19.3',
    terraform:          '0.13.5',
    terragrunt:         '0.20.3',
    iam_authenticator:  '1.14.6/2019-08-22',
    Packer:             '1.3.2',
    OpenStack_cli:      '3.17',
    ShellCheck:         'v0.4.6'
  },
  #-- customize with those
  transfer_local_files: {
    '~/.ssh/id_rsa'                 => '~/.ssh/id_rsa',
    '~/.ssh/id_rsa.pub'             => '~/.ssh/id_rsa.pub',
    'homedir/.bashrc'               => '~/.bashrc',
    'homedir/.git-completion.bash'  => '~/.git-completion.bash',
    'homedir/.git-prompt.bash'      => '~/.git-prompt.bash',
    'homedir/.vimrc'                => '~/.vimrc'
  }
}

####### Vagrant Prerequisites
module OS
    def OS.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def OS.mac?
        (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def OS.unix?
        !OS.windows?
    end

    def OS.linux?
        OS.unix? and not OS.mac?
    end
end


virt_hypervisor = 'virtualbox '
detected_os = 'linux'
required_plugins = %w(vagrant-vbguest)

if OS.mac? then
	virt_hypervisor = 'virtualbox '
	detected_os = 'macos'
end

if OS.linux? then
	required_plugins.push('vagrant-libvirt')
	virt_hypervisor = 'libvirt'
	detected_os = 'linux'
end

if OS.windows? then
	#-- nfs sharing
	required_plugins.push('vagrant-winnfsd')
	detected_os = 'windows'
end

required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

def file_dir_or_symlink_exists?(path_to_file)
  File.exist?(File.expand_path(path_to_file)) || File.symlink?(File.expand_path(path_to_file))
end

######
puts "Detected OS: #{detected_os}"
puts "Using Hypervisor: #{virt_hypervisor}"

####### SCRIPTS
install_BASE = <<SCRIPT
  cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
  echo "Installing base ..."
  yum install -y epel-release redhat-lsb ntpdate rpcbind
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
SCRIPT

#--
install_DEV = <<SCRIPT
  echo "Installing DEV ..."
  yum install -y tmux mc vim-enhanced git svn patch unzip gcc ruby rubygems curl bash-completion strace telnet bind-utils tcpdump nc traceroute telnet whois wget pwkickstart python-boto3 atop
SCRIPT

#--
install_chefDK = <<SCRIPT
  echo "Installing ChefDK ..."
  yum install -y https://packages.chef.io/files/stable/chefdk/#{GLOBAL_CONFIGS[:software_versions][:Chef_DK]}/el/7/chefdk-#{GLOBAL_CONFIGS[:software_versions][:Chef_DK]}-1.el7.x86_64.rpm 
  true
SCRIPT

#--
install_DOCKER = <<SCRIPT
  echo "Installing Docker ..."
  wget https://download.docker.com/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
  yum install -y docker-ce
  echo "DOCKER_NETWORK_OPTIONS='-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock'" | sudo tee /etc/sysconfig/docker-network > /dev/null
  sudo mkdir -p /etc/systemd/system/docker.service.d/
  echo "[Service]" | sudo tee /etc/systemd/system/docker.service.d/service.conf
  echo "EnvironmentFile=-/etc/sysconfig/docker-network" | sudo tee -a /etc/systemd/system/docker.service.d/service.conf
  echo "ExecStart=" | sudo tee -a /etc/systemd/system/docker.service.d/service.conf
  echo "ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock \\$DOCKER_NETWORK_OPTIONS" | sudo tee -a /etc/systemd/system/docker.service.d/service.conf
  sudo systemctl daemon-reload && systemctl enable docker && sudo systemctl restart docker
  echo -e 'export DOCKER_HOST=tcp://127.0.0.1:2375\nunset DOCKER_CERT_PATH\nunset DOCKER_TLS_VERIFY' > /etc/profile.d/docker_TCP.sh
  echo -e 'Run:\n  export DOCKER_HOST=tcp://127.0.0.1:2375 && unset DOCKER_CERT_PATH && unset DOCKER_TLS_VERIFY\nto use docker on the host machine'
SCRIPT

install_DOCKERSLIM = <<SCRIPT
  echo "Installing Docker-slim ..."
  docker_slimDir=/opt/dockerslim-#{GLOBAL_CONFIGS[:software_versions][:docker_slim]}
  mkdir -p $docker_slimDir
  wget https://downloads.dockerslim.com/releases/#{GLOBAL_CONFIGS[:software_versions][:docker_slim]}/dist_linux.tar.gz -O ${docker_slimDir}/docker_slim_#{GLOBAL_CONFIGS[:software_versions][:docker_slim]}.tar.gz
  tar -C ${docker_slimDir} -zxf  ${docker_slimDir}/docker_slim_#{GLOBAL_CONFIGS[:software_versions][:docker_slim]}.tar.gz
  chmod +x ${docker_slimDir}/dist_linux/*
  chown -R vagrant:vagrant ${docker_slimDir}
  ln -sf ${docker_slimDir}/dist_linux/docker-slim /usr/bin/docker-slim
  ln -sf ${docker_slimDir}/dist_linux/docker-slim-sensor /usr/bin/docker-slim-sensor
SCRIPT


#--
install_TFENV = <<SCRIPT
  echo "Installing TFenv for Terraform ..."
  tfenvDir=/opt/tfenv
  mkdir -p $tfenvDir
  wget https://github.com/vulturm/tfenv/archive/v#{GLOBAL_CONFIGS[:software_versions][:tfenv]}.zip -O /opt/tfenv_#{GLOBAL_CONFIGS[:software_versions][:tfenv]}.zip
  unzip -q -o /opt/tfenv_#{GLOBAL_CONFIGS[:software_versions][:tfenv]}.zip -d ${tfenvDir}
  chown -R vagrant:vagrant ${tfenvDir}
  ln -sf ${tfenvDir}/tfenv-#{GLOBAL_CONFIGS[:software_versions][:tfenv]}/bin/tfenv /usr/bin/tfenv
  ln -sf ${tfenvDir}/tfenv-#{GLOBAL_CONFIGS[:software_versions][:tfenv]}/bin/terraform /usr/bin/terraform

  # install our desired version of terraform
  tfenv install #{GLOBAL_CONFIGS[:software_versions][:terraform]}
  tfenv use #{GLOBAL_CONFIGS[:software_versions][:terraform]}
SCRIPT

install_TERRAGRUNT = <<SCRIPT
  echo "Installing Terragrunt ..."
  terragruntDir=/opt/terragrunt
  mkdir -p $terragruntDir
  wget https://github.com/gruntwork-io/terragrunt/releases/download/v#{GLOBAL_CONFIGS[:software_versions][:terragrunt]}/terragrunt_linux_amd64 -O ${terragruntDir}/terragrunt_#{GLOBAL_CONFIGS[:software_versions][:terragrunt]}
  chmod +x ${terragruntDir}/terragrunt_#{GLOBAL_CONFIGS[:software_versions][:terragrunt]}
  chown -R vagrant:vagrant ${terragruntDir}
  ln -sf ${terragruntDir}/terragrunt_#{GLOBAL_CONFIGS[:software_versions][:terragrunt]} /usr/bin/terragrunt
SCRIPT

#--
install_HELM = <<SCRIPT
  echo "Installing Helm ..."
  helmDir=/opt/helm
  mkdir -p $helmDir
  wget https://get.helm.sh/helm-v#{GLOBAL_CONFIGS[:software_versions][:helm]}-linux-amd64.zip -O /opt/helm_#{GLOBAL_CONFIGS[:software_versions][:helm]}.zip
  unzip -q -o /opt/helm_#{GLOBAL_CONFIGS[:software_versions][:helm]}.zip -d ${helmDir}
  chown -R vagrant:vagrant ${helmDir}
  ln -sf ${helmDir}/linux-amd64/helm /usr/bin/helm

SCRIPT

install_K9S = <<SCRIPT
  echo "Installing k9s ..."
  k9sDir=/opt/k9s
  mkdir -p $k9sDir
  wget https://github.com/derailed/k9s/releases/download/v#{GLOBAL_CONFIGS[:software_versions][:k9s]}/k9s_Linux_x86_64.tar.gz -O ${k9sDir}/k9s_#{GLOBAL_CONFIGS[:software_versions][:k9s]}.tar.gz
  tar -C ${k9sDir} -zxf  ${k9sDir}/k9s_#{GLOBAL_CONFIGS[:software_versions][:k9s]}.tar.gz
  chmod +x ${k9sDir}/k9s
  chown -R vagrant:vagrant ${k9sDir}
  ln -sf ${k9sDir}/k9s /usr/bin/k9s
SCRIPT

install_IAM_AUTHENTICATOR = <<SCRIPT
  echo "Installing AWS IAM Authenticator ..."
  iam_authenticatorDir=/opt/iam_authenticator
  mkdir -p $iam_authenticatorDir
  wget https://amazon-eks.s3-us-west-2.amazonaws.com/#{GLOBAL_CONFIGS[:software_versions][:iam_authenticator]}/bin/linux/amd64/aws-iam-authenticator -O ${iam_authenticatorDir}/aws-iam-authenticator
  chmod +x ${iam_authenticatorDir}/aws-iam-authenticator
  chown -R vagrant:vagrant ${iam_authenticatorDir}
  ln -sf ${iam_authenticatorDir}/aws-iam-authenticator /usr/bin/aws-iam-authenticator
SCRIPT

#--
install_PACKER = <<SCRIPT
  echo "Installing Packer ..."
  packerDir=/opt/packer
  mkdir -p $packerDir
  wget --content-dis -k https://releases.hashicorp.com/packer/#{GLOBAL_CONFIGS[:software_versions][:Packer]}/packer_#{GLOBAL_CONFIGS[:software_versions][:Packer]}_linux_amd64.zip -O /opt/packer_#{GLOBAL_CONFIGS[:software_versions][:Packer]}_linux_amd64.zip
  unzip -q -o /opt/packer_#{GLOBAL_CONFIGS[:software_versions][:Packer]}_linux_amd64.zip -d ${packerDir}
  chown -R vagrant:vagrant ${packerDir}
  ln -sf ${packerDir}/packer /usr/bin/packer
SCRIPT

#--
install_OPENSTACK = <<SCRIPT
  echo "Installing OpenStack Client ..."
  yum install -y python-devel python-pip
  pip install python-openstackclient==#{GLOBAL_CONFIGS[:software_versions][:OpenStack_cli]}
SCRIPT

#--
install_BASH = <<SCRIPT
  echo "Installing Bash Development Environment ..."
  shellcheckDir=/opt/shellcheck
  mkdir -p $shellcheckDir
  wget -k https://github.com/xxmitsu/dev_bin/blob/master/shellcheck-#{GLOBAL_CONFIGS[:software_versions][:ShellCheck]}.linux.x86_64.tar.xz?raw=true -O ${shellcheckDir}/shellcheck-#{GLOBAL_CONFIGS[:software_versions][:ShellCheck]}.linux.x86_64.tar.xz
  cd ${shellcheckDir} && tar xxf shellcheck-#{GLOBAL_CONFIGS[:software_versions][:ShellCheck]}.linux.x86_64.tar.xz
  chown -R vagrant:vagrant ${shellcheckDir}
  ln -sf ${shellcheckDir}/shellcheck-#{GLOBAL_CONFIGS[:software_versions][:ShellCheck]}/shellcheck /usr/bin/shellcheck
SCRIPT

#--
install_ANSIBLE = <<SCRIPT
  echo "Installing Ansible Development Environment ..."
  yum -y install ansible ansible-doc ansible-lint
SCRIPT

#--
install_ICINGA = <<SCRIPT
  echo "Installing Icinga Test Environment ..."
  wget https://packages.icinga.com/epel/ICINGA-release.repo -O /etc/yum.repos.d/ICINGA-release.repo
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

##############################
### VMs
VIRTUAL_MACHINES = {
  workstation: {
    vm_box: 'centos/7',
    hostname: 'workstation.local.lo',
    cpus: 6,
    memory: 4096,
    provider: virt_hypervisor,
    private_ip: '192.168.199.30',
    environment: 'DevOps',
    shell_script: [ 
      install_BASE,
      install_DEV,
      install_TFENV,
      install_K9S,
      install_HELM,
      install_IAM_AUTHENTICATOR,
      install_TERRAGRUNT,
      install_PACKER,
      install_ANSIBLE,
      install_OPENSTACK,
      install_BASH,
      install_DOCKER,
      install_DOCKERSLIM
    ]
  },
  node2test: {
    vm_box: 'centos/7',
    hostname: 'node2test.local.lo',
    cpus: 2,
    memory: 1024,
    provider: virt_hypervisor,
    sync_folder: '/Users/mihaiv2/Downloads',
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
    provider: virt_hypervisor,
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
    provider: virt_hypervisor,
    private_ip: '192.168.199.23',
    environment: 'DevOps',
    shell_script: [
      install_BASE,
      install_DEV
    ]
  },
#   fedora30test: {
#     vm_box: 'fedora/30-cloud-base',
# #    vm_box: 'centos/7',
#     hostname: 'fedora30test.local.lo',
#     cpus: 2,
#     memory: 2500,
#     private_ip: '192.168.199.24',
#     environment: 'DevOps'
#   },

}.freeze

##############################
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  #  config.omnibus.chef_version = '12.8.1'
  config.vbguest.auto_update = false if Vagrant.has_plugin?('vagrant-vbguest')
  config.vm.synced_folder ".", "/vagrant", :disabled => true

  VIRTUAL_MACHINES.each do |name, cfg|
    config.vm.box = cfg[:vm_box]
      if cfg[:sync_folder] then
	if OS.mac? then
	  config.vm.synced_folder cfg[:sync_folder], "/vagrant", type: "nfs"
	end
      end

    config.vm.define name do |vm_config|
      vm_config.berkshelf.enabled = false if Vagrant.has_plugin?('vagrant-berkshelf')
      # private net between
      if cfg[:provider] == 'libvirt'
        vm_config.vm.network :private_network,
          ip: cfg[:private_ip],
          auto_config: false,
          libvirt__domain_name: cfg[:hostname],
          libvirt__dhcp_enabled: false,
          libvirt__forward_mode: "nat"
      else
        # vm_config.vm.network 'private_network', virtualbox__intnet: 'intnet'
        vm_config.vm.network 'private_network', ip: cfg[:private_ip]
      end
      vm_config.vm.hostname = cfg[:hostname]

      if cfg[:provider] == 'libvirt'
        config.vm.provider :libvirt do |libvirt|
          libvirt.host = cfg[:hostname]
          libvirt.memory = cfg[:memory]
          libvirt.cpus = cfg[:cpus]
          libvirt.cpu_mode = "host-passthrough"

          # Use QEMU session instead of system connection
          libvirt.qemu_use_session = true
          # URI of QEMU session connection, default is as below
          libvirt.uri = 'qemu:///session'
          # URI of QEMU system connection, use to obtain IP address for management, default is below
          libvirt.system_uri = 'qemu:///system'
          # Management network device, default is below
          libvirt.management_network_device = 'virbr0'
          libvirt.driver = "kvm"
          libvirt.host = 'localhost'
          libvirt.uri = 'qemu:///system'
        end
      else
        vm_config.vm.provider 'virtualbox' do |virtualbox|
          virtualbox.name = cfg[:hostname]
          virtualbox.customize ['modifyvm', :id, '--memory', cfg[:memory]]
          virtualbox.customize ['modifyvm', :id, '--cpus', cfg[:cpus]]
          # perf
          virtualbox.customize ['modifyvm', :id, '--macaddress1', "auto"]
          virtualbox.customize ['modifyvm', :id, '--paravirtprovider', 'default']
          virtualbox.customize ['modifyvm', :id, '--ioapic', 'on']
          virtualbox.customize ['modifyvm', :id, '--hwvirtex', 'on']
          virtualbox.customize ["modifyvm", :id, "--chipset", "ich9"]
          # prevent time drift
          virtualbox.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-interval", 10000]
          virtualbox.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-min-adjust", 100]
          virtualbox.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-on-restore", 1]
          virtualbox.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 60000]
        end
      end
      #--
      if GLOBAL_CONFIGS[:transfer_local_files]
        GLOBAL_CONFIGS[:transfer_local_files].each do |src_name, dst_name|
          vm_config.vm.provision 'file', source: File.expand_path(src_name), destination: dst_name if file_dir_or_symlink_exists?(src_name)
        end
      end
      #--
      if cfg[:shell_script]
	      cfg[:shell_script].each do |provision_with|
		      vm_config.vm.provision :shell, :inline => provision_with
	      end
      end
      #--
      if cfg[:forwarded_ports]
        cfg[:forwarded_ports].each do |port|
          vm_config.vm.network 'forwarded_port', guest: port[:guest], host: port[:host]
        end
      end
    end
  end
end 
