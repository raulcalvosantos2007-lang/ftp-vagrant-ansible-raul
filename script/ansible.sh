#!/usr/bin/env bash
#
# Configura el servidor como un nodo de control de Ansible
#
set -xeu

# Instalar ansible y herramientas de apoyo para las pruebas
apt-get update
apt-get install -y ansible ansible-lint whois dnsutils curl

#
# Copia clave privada de Vagrant para conectarse a las MVs
#
# Para evitar problemas con Windows y los permisos, en lugar de utilizar las
# claves privadas compartidas en /vagrant/.vagrant/... copiamos las claves
# privadas dentro de la MV `ansible` y establecemos los permisos adecuados
#
mkdir -p ./private_keys/{dns,negocio}
cp -vf /vagrant/.vagrant/machines/dns/virtualbox/private_key ./private_keys/dns.key.rsa
cp -vf /vagrant/.vagrant/machines/negocio/virtualbox/private_key ./private_keys/negocio.key.rsa
chown vagrant:vagrant ./private_keys/*
chmod 600 ./private_keys/*

# Copiar ficheros de ansible y playbooks
cp -vf /vagrant/ansible.cfg .
chown vagrant:vagrant ./ansible.cfg

cp -vf /vagrant/inventory.yml .
chown vagrant:vagrant ./inventory.yml

cp -vf /vagrant/requirements.yml .
chown vagrant:vagrant ./requirements.yml

cp -vrf /vagrant/dns .
chown -R vagrant:vagrant ./dns

cp -vrf /vagrant/web .
chown -R vagrant:vagrant ./web

cp -vrf /vagrant/ftp .
chown -R vagrant:vagrant ./ftp

# Copiar contraseña del vault
cp -vf /vagrant/vault_pass.txt ./.vault_pass.txt
chown vagrant:vagrant ./.vault_pass.txt
chmod 600 ./.vault_pass.txt

# Instalar dependencias de Ansible como el usuario vagrant (ejecutará los playbooks)
sudo -u vagrant env HOME=/home/vagrant ansible-galaxy collection install -r requirements.yml

# Los playbooks se ejecutan manualmente desde `vagrant ssh ansible`, en este
# orden, para poder comprobar cada apartado antes de continuar:
# ansible-playbook dns/dns.yml
# ansible-playbook web/web.yml
# ansible-playbook ftp/ftp.yml --vault-password-file ./.vault_pass.txt
