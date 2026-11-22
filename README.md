# FTP con Vagrant y Ansible como nodo controlador

**Alumno:** Raúl  
**Dominio de la práctica:** `raul.test`  
**Repositorio:** `https://github.com/raulcalvosantos2007-lang/ftp-vagrant-ansible-raul`

## Objetivo del proyecto

Desplegar de forma automatizada un entorno de prácticas con tres máquinas virtuales
Debian Bookworm gestionadas por Vagrant:

- `dns.raul.test` (`192.168.57.5`): servidor DNS con BIND9.
- `ansible.raul.test` (`192.168.57.6`): nodo de control de Ansible.
- `negocio.raul.test` (`192.168.57.7`): servidor web Apache y servidor FTP seguro
  `vsftpd` con TLS, usuarios locales y restricciones de acceso.

El objetivo es automatizar la instalación y configuración de todos los servicios
mediante playbooks de Ansible, verificar la resolución de nombres, probar el
servidor web y comprobar las políticas de acceso FTP con un cliente real.

## Herramientas utilizadas

- **GitHub**: control de versiones, issues y GitHub Projects.
- **Vagrant** y **Oracle VirtualBox**: infraestructura virtual reproducible.
- **Ansible**: aprovisionamiento de los servicios.
- **Ansible Vault**: cifrado de los hashes de contraseñas.
- **BIND9**: DNS directo e inverso.
- **Apache2**: servidor web.
- **vsftpd** + **TLS**: servidor FTP seguro.
- **community.crypto**: generación del certificado autofirmado.
- **FileZilla/WinSCP o `ftplib` con FTP_TLS**: pruebas del servicio FTP.

## Requisitos

- Windows 10/11 con virtualización activada.
- Vagrant 2.4.x y Oracle VirtualBox 7.x.
- Git y OpenSSH disponibles en el anfitrión.
- Conexión a Internet para descargar paquetes y la colección `community.crypto`.
- Al menos 3 GB de RAM libres para las tres máquinas virtuales.

## Puesta en marcha básica

1. Desde la raíz del repositorio:

   ```powershell
   vagrant up
   ```

   Vagrant crea las tres máquinas y ejecuta `script/ansible.sh` en el nodo
   `ansible`: instala Ansible y copia las claves privadas de `dns` y `negocio`
   dentro de la VM (nunca se suben al repositorio).

2. En el nodo de control:

   ```powershell
   vagrant ssh ansible
   ```

   Desde allí se pueden ejecutar, en orden:

   ```bash
   ansible-inventory --graph
   ansible all -m ping
   ansible all -b -a "uptime"
   ansible-playbook dns/dns.yml
   ansible-playbook web/web.yml
   ansible-playbook ftp/ftp.yml --vault-password-file ./.vault_pass.txt
   ```

3. Después de provisionar DNS, configurar los resolvers internos de las VMs:

   ```bash
   ./scripts/configurar_dns_interno.sh
   ```

   Este paso se ejecuta desde el anfitrión y permite probar `www.raul.test` y
   `ftp.raul.test` desde dentro del entorno.

4. Para que el navegador del anfitrión resuelva los nombres `*.raul.test` es
   necesario configurar el DNS primario de Windows con `192.168.57.5` (o añadir
   entradas al archivo `hosts`). Este cambio es manual y se documenta en
   `documentacion/INFORME_FINAL.md`.

5. Evidencias, comprobaciones y documentación adicional están en
   `evidencias/` y `documentacion/`.

## Seguridad de esta práctica

`ansible.cfg` desactiva la comprobación de claves de host SSH y usa el
usuario `vagrant` con una clave conocida. Ello simplifica el laboratorio, pero
**no es apto para producción**. Las contraseñas de los usuarios FTP se guardan
como hashes SHA-512-crypt dentro de `ftp/vars/vault.yml`, cifrado con Ansible
Vault. La password maestra se mantiene en `vault_pass.txt`, ignorada por Git.
