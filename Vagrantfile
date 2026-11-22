Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "dns" do |dns|
    dns.vm.hostname = "dns.raul.test"
    dns.vm.network "private_network", ip: "192.168.57.5"
    dns.vm.provider "virtualbox" do |vb|
      vb.name = "raul-practica-dns"
      vb.memory = 1024
      vb.cpus = 1
    end
  end

  config.vm.define "negocio" do |negocio|
    negocio.vm.hostname = "negocio.raul.test"
    negocio.vm.network "private_network", ip: "192.168.57.7"
    negocio.vm.provider "virtualbox" do |vb|
      vb.name = "raul-practica-negocio"
      vb.memory = 1024
      vb.cpus = 1
    end
  end

  config.vm.define "ansible" do |ansible|
    ansible.vm.hostname = "ansible.raul.test"
    ansible.vm.network "private_network", ip: "192.168.57.6"
    ansible.vm.provider "virtualbox" do |vb|
      vb.name = "raul-practica-ansible"
      vb.memory = 1024
      vb.cpus = 1
    end
    ansible.vm.provision "shell", path: "script/ansible.sh"
  end
end
