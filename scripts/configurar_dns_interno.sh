#!/usr/bin/env bash
# Configura el resolver de las tres VMs para usar el DNS de la práctica.
# Se ejecuta desde la raíz del repositorio, en el anfitrión, después de dns.yml.
set -euo pipefail

for vm in dns negocio ansible; do
    printf 'Configurando resolver en %s...\n' "$vm"
    vagrant ssh "$vm" -c 'echo "nameserver 192.168.57.5" | sudo tee /etc/resolv.conf >/dev/null'
done

printf '\nLos resolvers internos apuntan a 192.168.57.5.\n'
