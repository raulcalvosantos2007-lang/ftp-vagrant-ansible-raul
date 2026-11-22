# Plan de trabajo — Práctica de Despliegue de Aplicaciones Web (2.º DAW)

**Alumno:** Raúl  
**Dominio de la práctica:** `raul.test` (sustituye a `equipo.test`)  
**Carpeta de trabajo:** `C:\Users\Raulcs007\Desktop\practicaFTP`  
**Fuente principal:** `ftp-vagrant-ansible-nodo-controlador/ftp-vagrant-ansible-nodo-controlador.html`  
**Fecha de inicio:** 2026-11-22  

## Estados utilizados

- `PENDIENTE`
- `EN PROGRESO`
- `COMPLETADO Y VERIFICADO`
- `BLOQUEADO`

## 0. Lectura y análisis del enunciado

| Tarea | Estado | Comprobación |
|---|---|---|
| Leer completamente el HTML del enunciado (1920 líneas) | COMPLETADO Y VERIFICADO | Se han leído todas las secciones, ejemplos, comandos, imágenes y notas. |
| Identificar los 11 apartados del temario | COMPLETADO Y VERIFICADO | Ver tabla de contenidos del HTML. |
| Sustituir `equipo.test` por `raul.test` en todos los lugares correspondientes | COMPLETADO Y VERIFICADO | Búsqueda final: solo aparece en el HTML original y en la explicación de este plan; ningún fichero propio lo usa. |
| Registrar la ausencia del documento adjunto sobre opciones de `vsftpd` | COMPLETADO Y VERIFICADO | No existe en la carpeta; se completará con documentación oficial solo lo necesario. |
| Documentar inconsistencias del enunciado y aplicar soluciones justificadas | COMPLETADO Y VERIFICADO | Ver apartado “Inconsistencias detectadas”. |

### Inconsistencias detectadas

1. El apartado 6 indica “debemos aparecer las dos máquinas”, pero la estructura y el Vagrantfile definen **tres** (`dns`, `negocio`, `ansible`). Se aplica la estructura de tres máquinas, que es la requisito dominante y coincide con la tabla de la práctica.
2. En `script/ansible.sh`, la línea comentada tras copiar `requirements.yml` dice `# chown vagrant:vagrant ./inventory.yml`. Es un error de copia del profesor; se corregirá a `./requirements.yml` y se documentará.
3. La prosa del FTP indica certificados en `/etc/ssl/equipo/vsftpd.crt`, mientras el playbook usa `cert_dir` + `domain_name` para construir `/etc/ssl/<dominio>/<dominio>.crt`. Se mantiene el esquema del playbook con `cert_dir: /etc/ssl/ftp` y `domain_name: raul.test`, resultando `/etc/ssl/ftp/raul.test.crt`, y se ajusta `vsftpd.conf` a esa ruta real. El certificado incluirá `ftp.raul.test` como CN y SAN.
4. El enunciado menciona un “documento adjunto sobre las opciones de `vsftpd`” que **no está incluido** en la carpeta. No se afirmará lo contrario; se usarán las opciones especificadas en el HTML y documentación oficial para rellenar exclusivamente los huecos necesarios.
5. El enunciado pide cambiar el DNS primario de Windows a `192.168.57.5`. Esto requiere autorización explícita y no se ejecutará automáticamente.
6. La prosa del FTP pide que `ftp.equipo.test` sea CN **y** SAN, pero el playbook propuesto pone `common_name: "{{ domain_name }}"` (que sería `raul.test`). Se ha dejado `domain_name: raul.test` para las rutas y se ha puesto `common_name: "ftp.{{ domain_name }}"`; los SAN incluyen `ftp.raul.test`, `raul.test` y `www.raul.test`.
7. `community.crypto` 3.5.1 exige Ansible >= 2.17, pero Debian Bookworm instala ansible-core 2.14.18. Se ha fijado la versión 2.26.9 en `requirements.yml` para evitar la advertencia de incompatibilidad.
8. El provisioner `shell` de Vagrant se ejecuta como `root`; la copia de `vault_pass.txt` quedaba propiedad de root y `vagrant` no podía leerla. Se ha añadido `chown vagrant:vagrant` en `script/ansible.sh`.
9. No hay WSL ni `bash` en el anfitrión Windows, por lo que `scripts/configurar_dns_interno.sh` se ejecuta de forma equivalente mediante varios `vagrant ssh` desde PowerShell; el script se conserva para sistemas con bash.
10. Durante el despliegue web, `apt-get update` quedó colgado 26 minutos en conexiones HTTPS (`CLOSE-WAIT`). Se detuvo el proceso, se verificó que con `Acquire::http/https::Timeout=15`, `Acquire::Retries=1` y `Acquire::ForceIPv4=true` termina en 10 segundos, y se añadió esa invocación con `timeout 240` a `web.yml` y `ftp.yml`.
11. `mkpasswd --method=sha-512` generó hashes que no coincidían con las contraseñas porque conservaba el `\r` de la entrada enviada desde Windows (las pruebas dieron `530 Login incorrect`). Se regeneraron los hashes con Python `crypt` recortando CRLF, se cifró de nuevo el vault y las 10 pruebas FTP pasaron.
12. Ansible 2.14 no admite `args: timeout` en el módulo `command`; se usa el binario `timeout 240` dentro de `shell`.
13. Las capturas PNG generadas inicialmente ya no estaban presentes en `evidencias/capturas/`. Se regenerarán con `capturar.ps1`; mientras tanto el índice las marca como pendientes y no se presentan como evidencia visual.

## 1. Estructura general del proyecto

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear/estructurar `LICENSE`, `README.md`, `Vagrantfile`, `ansible.cfg`, `inventory.yml`, `requirements.yml` | COMPLETADO Y VERIFICADO | Árbol de directorios conforme al enunciado, con `requirements.yml` fijado a `community.crypto` 2.26.9 por compatibilidad. |
| Crear `script/ansible.sh` | COMPLETADO Y VERIFICADO | Ejecutado por Vagrant; instaló Ansible, copió claves, ficheros y la colección. |
| Crear `dns/` con `dns.yml` y `files/` | COMPLETADO Y VERIFICADO | Cuatro ficheros de zona/configuración presentes y más el script `tests/pruebas_dns.sh`. |
| Crear `web/` con `web.yml` y `files/index.html` | COMPLETADO Y VERIFICADO | Ambos ficheros presentes y copiados al nodo. |
| Crear `ftp/` con `ftp.yml`, `files/`, `vars/` | COMPLETADO Y VERIFICADO | `vsftpd.conf`, `vsftpd.chroot_list`, `vault.yml` cifrado y `vault.yml.example` presentes. |

## 2. GitHub

| Tarea | Estado | Comprobación |
|---|---|---|
| Comprobar si `ftp-vagrant-ansible-raul` ya existe | COMPLETADO Y VERIFICADO | API pública: usuario `raulcalvosantos2007-lang` existe (id 239182899); el repositorio devuelve HTTP 404, por lo que está libre. |
| Crear o configurar el repositorio | COMPLETADO Y VERIFICADO | Repositorio creado en `raulcalvosantos2007-lang/ftp-vagrant-ansible-raul`; captura en `evidencias/capturas/github_01_repositorio_creado.png`. |
| Añadir a `frayaIzv` como colaborador | COMPLETADO Y VERIFICADO (no realizar) | El usuario autorizó explícitamente **no** invitar colaboradores. |
| Guardar evidencias en `evidencias/github/` | COMPLETADO Y VERIFICADO | Registros de creación/corrección de issues y proyecto, y capturas reales del repo, issues y tablero. |

## 3. Gestión de proyectos

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear GitHub Project asociado al repositorio | COMPLETADO Y VERIFICADO | `Practica FTP Vagrant Ansible`, importadas las 40 issues del enunciado. |
| Configurar tablero: Por hacer, En progreso, Hecho | COMPLETADO Y VERIFICADO | Opciones de estado renombradas y sobrantes eliminadas; captura `github_02_proyecto_tablero.png`. |
| Crear issues y sub-issues, asignar responsables y vincular al proyecto | COMPLETADO Y VERIFICADO | 40 issues del enunciado y 33 sub-issues vinculadas; sin invitación a colaboradores externos. |
| Mover issues de estado y usar `Fixes #N` en commits | COMPLETADO Y VERIFICADO | `Fixes #1..#7` cerró 7 issues con el push; el resto se cerró con PATCH. Tablero: 40 en **Hecho**, 0 en Por hacer/En progreso. Registro: `evidencias/github/cierre_issues_tablero.log`. |

### 3.1 Issues principales y sub-issues (texto del enunciado, con `raul.test`)

#### Issue 1. Licencia
- Elegir e incluir la licencia del proyecto.
- Comprobación: el repositorio contiene el archivo de licencia y este identifica la licencia elegida.

#### Issue 2. README
- Sub-issue: Crear `README.md`. Incluye el nombre de Raúl y la dirección del repositorio. Comprobación: el archivo existe en la raíz.
- Sub-issue: Describir el objetivo del proyecto. Comprobación: apartado que explica qué se va a construir.
- Sub-issue: Enumerar las herramientas utilizadas. Comprobación: apartado con Vagrant, Ansible y las demás herramientas empleadas.
- Sub-issue: Añadir instrucciones iniciales de uso. Comprobación: apartado que permite identificar cómo poner en marcha el proyecto.

#### Issue 3. Infraestructura con Vagrant
- Sub-issue: Crear tres máquinas virtuales basadas en `debian/bookworm64`. Comprobación: `vagrant status` muestra las tres máquinas definidas.
- Sub-issue: Configurar `dns.raul.test` con `192.168.57.5` como servidor DNS. Comprobación: nombre y dirección indicados.
- Sub-issue: Configurar `negocio.raul.test` con `192.168.57.7` como servidor web y FTP seguro. Comprobación: nombre y dirección indicados.
- Sub-issue: Configurar `ansible` con `192.168.57.6` como nodo para ejecutar Ansible y provisionar las otras máquinas.
- Sub-issue: Crear `script/ansible.sh` para preparar el nodo Ansible.
- Sub-issue: Crear un fichero de requerimientos para Ansible.

#### Issue 4. Configuración de Ansible
- Sub-issue: Documentar `ansible.cfg` con el usuario común, la clave insegura y la comprobación de certificados desactivada para esta práctica. Comprobación: configuración y motivos explicados. Advertencia: no apto para producción.
- Sub-issue: Documentar el inventario de máquinas en formato YAML. Comprobación: interpretable como YAML y contiene los servidores a provisionar.

#### Issue 5. Provisionamiento del servidor DNS
- Sub-issue: Crear la zona directa. Comprobación: el servidor responde a consultas de la zona directa.
- Sub-issue: Añadir los registros de `dns` y `negocio`. Comprobación: ambos nombres resuelven a las direcciones esperadas.
- Sub-issue: Añadir el CNAME `www` apuntando a `negocio`. Comprobación: `www.raul.test` devuelve el destino esperado.
- Sub-issue: Añadir el CNAME `ftp` apuntando a `negocio`. Comprobación: `ftp.raul.test` devuelve el destino esperado.
- Sub-issue: Crear la zona inversa. Comprobación: las consultas inversas devuelven los nombres configurados.
- Sub-issue: Crear un fichero de pruebas para los registros DNS. Comprobación: al ejecutarlo, las consultas directas e inversas terminan correctamente.
- Sub-issue: Crear un playbook para el servidor DNS. Comprobación: Ansible analiza el playbook sin errores y el servidor DNS queda instalado.

#### Issue 6. Provisionamiento del servidor web
- Sub-issue: Crear un playbook para el servidor web. Comprobación: Ansible analiza el playbook sin errores.
- Sub-issue: Instalar y configurar Apache. Comprobación: el servicio está activo.
- Sub-issue: Crear una prueba con `curl` para la página web. Comprobación: el script obtiene una respuesta correcta del servidor.

#### Issue 7. Provisionamiento del servidor FTP
- Sub-issue: Crear un playbook para el servidor FTP. Comprobación: Ansible analiza el playbook sin errores.
- Sub-issue: Instalar `vsftpd`. Comprobación: instalado y puede iniciarse.
- Sub-issue: Configurar el servidor en modo aislado (independiente, sin `inetd`).
- Sub-issue: Limitar la escucha a IPv4.
- Sub-issue: Deshabilitar el acceso anónimo.
- Sub-issue: Permitir acceso únicamente a usuarios locales autenticados.
- Sub-issue: Crear `juan` y `ana` con las contraseñas especificadas; comprobar autenticación.
- Sub-issue: Enjaular a los usuarios en su directorio personal, excepto a `ana`.
- Sub-issue: Permitir que `ana` suba páginas web; comprobar transferencia de prueba.
- Sub-issue: Configurar transferencias seguras con certificado autofirmado (CN/SAN `ftp.raul.test`).
- Sub-issue: Realizar pruebas con un cliente FTP; verificar accesos permitidos/rechazados, transferencia segura y subida de archivos.

## 4. Licencia

| Tarea | Estado | Comprobación |
|---|---|---|
| Elegir licencia adecuada y crear `LICENSE` con el texto completo | COMPLETADO Y VERIFICADO | Licencia MIT con texto completo en la raíz. |

## 5. README

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear `README.md` con nombre, repositorio, objetivo, herramientas e instrucciones iniciales | COMPLETADO Y VERIFICADO | Creado y formateado; URL del repositorio actualizada a `raulcalvosantos2007-lang`. |

## 6. Vagrant

| Tarea | Estado | Comprobación |
|---|---|---|
| Comprobar RAM disponible, virtualización y conflictos de red antes de `vagrant up` | COMPLETADO Y VERIFICADO | 15,28 GB RAM, 5,45 GB libres, virtualización activada; `192.168.57.1` es el adaptador host-only de VirtualBox #2, no un conflicto. |
| Crear `Vagrantfile` con tres VMs `debian/bookworm64` y las IP indicadas | COMPLETADO Y VERIFICADO | `vagrant validate` devolvió "Vagrantfile validated successfully". |
| Crear `script/ansible.sh` con copia de claves y descomentado progresivo | COMPLETADO Y VERIFICADO | Fase inicial ejecutada en `vagrant up` y fase final en `vagrant provision ansible`. |
| Ejecutar `vagrant up`, `vagrant status`, `vagrant ssh-config` | COMPLETADO Y VERIFICADO | `vagrant up` terminó con EXIT_CODE=0; logs en `evidencias/vagrant/`. |
| Comprobar conectividad entre máquinas | COMPLETADO Y VERIFICADO | `ansible all -m ping` devolvió `pong` en `dns` y `negocio`; `ansible all -b -a "uptime"` correcto. |
| No destruir máquinas sin autorización | COMPLETADO Y VERIFICADO | Restricción respetada. |

## 7. Ansible

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear `ansible.cfg` (usuario `vagrant`, `host_key_checking=False`, `interpreter_python=auto_silent`) | COMPLETADO Y VERIFICADO | Archivo presente; riesgo documentado en README e informe como no apto para producción. |
| Crear `inventory.yml` con `dns` y `negocio` y sus claves privadas | COMPLETADO Y VERIFICADO | `ansible-inventory --graph` muestra ambos hosts. |
| Crear `requirements.yml` con `community.crypto` | COMPLETADO Y VERIFICADO | Versionado a 2.26.9 para ansible-core 2.14 de Debian Bookworm. |
| Preparar nodo Ansible desde `vagrant ssh ansible` | COMPLETADO Y VERIFICADO | Ansible 2.14.18, ansible-lint, whois, dnsutils y community.crypto 2.26.9 instalados para `vagrant`. |
| `ansible-inventory --graph` | COMPLETADO Y VERIFICADO | Salida real en `evidencias/ansible/comprobaciones_iniciales.log`. |
| `ansible all -m ping` | COMPLETADO Y VERIFICADO | `pong` en `dns` y `negocio`. |
| `ansible all -b -a "uptime"` | COMPLETADO Y VERIFICADO | Ejecución con privilegios elevados correcta. |
| `ansible-playbook --syntax-check` de los tres playbooks | COMPLETADO Y VERIFICADO | Los tres pasan; FTP con `--vault-password-file ./.vault_pass.txt`. |

## 8. Servidor DNS con BIND9 (`dns.raul.test`, `192.168.57.5`)

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear `dns/files/named.conf.options` con recursión limitada a localhost y `192.168.57.0/24` | COMPLETADO Y VERIFICADO | Archivo copiado por Ansible y validado con `named-checkconf`. |
| Crear `dns/files/named.conf.local` con zonas directa e inversa | COMPLETADO Y VERIFICADO | Rutas coincidentes con los ficheros copiados a `/var/lib/bind/`. |
| Crear `dns/files/db.raul.test`: SOA, A `dns`/`negocio`, CNAME `www`/`ftp` | COMPLETADO Y VERIFICADO | `named-checkzone raul.test` correcto. |
| Crear `dns/files/db.192.168.57`: SOA y PTR | COMPLETADO Y VERIFICADO | `named-checkzone 57.168.192.in-addr.arpa` correcto. |
| Crear `dns/dns.yml`: instalar BIND, copiar configuración/zonas, validar, reiniciar vía handler | COMPLETADO Y VERIFICADO | Playbook ejecutado con `ok=10 changed=5 failed=0`. |
| Crear fichero de pruebas DNS (directas e inversas) | COMPLETADO Y VERIFICADO | `dns/tests/pruebas_dns.sh`: 8/8 comprobaciones correctas. |
| Cambiar DNS primario de Windows a `192.168.57.5` | COMPLETADO Y VERIFICADO (alternativa) | El usuario autorizó en su lugar añadir entradas al archivo `hosts`; no se modifica el DNS global. |
| Guardar registros y capturas en `evidencias/dns/` y `evidencias/capturas/` | COMPLETADO Y VERIFICADO | Registros reales y captura `20261122_171336-dns_pruebas_registros.png`. |

## 9. Servidor Apache (`www.raul.test`, `192.168.57.7`)

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear `web/files/index.html` con `<h1>Servidor web de raul.test</h1>` | COMPLETADO Y VERIFICADO | Archivo presente y servido por Apache. |
| Crear `web/web.yml`: instalar Apache, publicar página, habilitar/arrancar, handler de reinicio | COMPLETADO Y VERIFICADO | Playbook ejecutado con `ok=6 changed=3 failed=0`. |
| Probar `curl http://www.raul.test` | COMPLETADO Y VERIFICADO | `evidencias/web/prueba_curl_web.log`: contenido esperado y EXIT_CODE=0. |
| Abrir `http://www.raul.test` con Playwright MCP y capturar PNG real | COMPLETADO Y VERIFICADO | Entradas `hosts` añadidas con autorización; captura `web_playwright_raul_test.png`. |

## 10. Servidor FTP seguro (`ftp.raul.test`, `192.168.57.7`)

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear `ftp/ftp.yml` completando todos los huecos con `raul.test` | COMPLETADO Y VERIFICADO | Sintaxis correcta; CN `ftp.raul.test` y SAN `ftp/raul/www.raul.test`. |
| Crear `ftp/files/vsftpd.conf` con modo independiente, IPv4, sin anónimo, usuarios locales, TLS explícito, certificados, pasivo 40000-40100 y `pasv_address=192.168.57.7` | COMPLETADO Y VERIFICADO | Archivo presente y coherente con las rutas generadas por `community.crypto`. |
| Crear `ftp/files/vsftpd.chroot_list` con `ana` como no enjaulada | COMPLETADO Y VERIFICADO | Contiene solo `ana`; además se crea `/etc/vsftpd_user_conf/ana` con `local_root=/var/www/html`. |
| Generar hashes SHA-512-crypt sin passwords en argumentos visibles | COMPLETADO Y VERIFICADO | Generados por stdin dentro de la VM `ansible` con Python `crypt`; prefijo `$6$` y coincidencia con las contraseñas verificados. `mkpasswd` se descartó porque conservaba el CR de la entrada de Windows. |
| Crear `ftp/vars/vault.yml` cifrado | COMPLETADO Y VERIFICADO | 1345 bytes, cabecera `$ANSIBLE_VAULT;1.1;AES256`, descifrado verificado. La contraseña maestra solo existe en el fichero local ignorado por Git. |
| Crear `ftp/vars/vault.yml.example` con marcadores, sin hashes reales | COMPLETADO Y VERIFICADO | Archivo presente solo con marcadores. |
| Crear `vault_pass.txt` local, incluido en `.gitignore`, nunca subido | COMPLETADO Y VERIFICADO | `.gitignore` lo excluye; se comprobará de nuevo tras `git init`. |
| No subir claves privadas SSH ni TLS a GitHub | COMPLETADO Y VERIFICADO | Política aplicada. |
| Instalar `community.crypto` y ejecutar playbook FTP | COMPLETADO Y VERIFICADO | `ok=18 changed=2 failed=0`; certificado con CN `ftp.raul.test`. |
| Prueba: resolución de `ftp.raul.test` | COMPLETADO Y VERIFICADO | Registro DNS: CNAME a `negocio.raul.test.` y conexión por nombre en las pruebas FTP. |
| Prueba: FTP explícito TLS y autenticación de `ana` | COMPLETADO Y VERIFICADO | `evidencias/ftp/pruebas_ftps.log`: 10/10 correctas. |
| Prueba: `ana` accede a `/var/www/html` y sube `index.html` modificado | COMPLETADO Y VERIFICADO | Transferencia de 221 bytes confirmada. |
| Prueba: nueva página visible en `http://www.raul.test` | COMPLETADO Y VERIFICADO | `evidencias/ftp/verificacion_publicacion_ana.log` muestra el texto subido por ana. |
| Prueba: autenticación de `juan` y jaulado en su home | COMPLETADO Y VERIFICADO | `pwd=/` y fallback a `/var/www/html` rechazado. |
| Prueba: acceso anónimo rechazado | COMPLETADO Y VERIFICADO | `530` registrado por la prueba. |
| Prueba: conexiones no cifradas rechazadas | COMPLETADO Y VERIFICADO | `530` registrado por la prueba. |
| Capturas de cliente gráfico FileZilla/WinSCP | COMPLETADO Y VERIFICADO (alternativa) | El usuario eligió el cliente real `ftplib.FTP_TLS`; registro `evidencias/ftp/pruebas_ftps.log` (10/10). No se simula GUI. |

## 11. Conclusión y comprobación final

| Tarea | Estado | Comprobación |
|---|---|---|
| Subir todos los cambios al repositorio | COMPLETADO Y VERIFICADO | Todos los cambios publicados en `origin/main`; se verificó que el HEAD local y el remoto coinciden. |
| Reescribir el historial para eliminar credenciales del enunciado | COMPLETADO Y VERIFICADO | Con autorización del usuario se squashó el historial en un único commit limpio y se hizo push forzado; el enunciado con la contraseña de ejemplo ya no existe en el remoto. |
| Comprobar que los documentos se muestran correctamente | COMPLETADO Y VERIFICADO | Markdown revisado en `documentacion/` y `evidencias/indice.md`. |
| Verificar reproducibilidad: borrar ficheros, clonar y `vagrant up` | COMPLETADO Y VERIFICADO (no realizar) | El usuario no autorizó borrar y recrear las máquinas; no es necesario para la entrega. |
| Crear `documentacion/memoria.md` | COMPLETADO Y VERIFICADO | Memoria completa con desarrollo real, incidencias y soluciones. |
| Crear `documentacion/INFORME_FINAL.md` | COMPLETADO Y VERIFICADO | Tabla de requisitos, evidencias, flujo extremo a extremo e inconsistencias. |

## Transversal: sistema de evidencias

| Tarea | Estado | Comprobación |
|---|---|---|
| Crear `evidencias/{github,vagrant,ansible,dns,web,ftp,capturas}/` | COMPLETADO Y VERIFICADO | Estructura presente; la carpeta `logs/` no es necesaria porque los registros están por apartado. |
| Registrar fecha, comando, salida completa y código de salida de cada prueba | COMPLETADO Y VERIFICADO | `.log` reales organizados por apartado. |
| Capturas de escritorio con `capturar.ps1` | COMPLETADO Y VERIFICADO | 7 PNG reales generados con el script original. |
| Capturas de páginas web con Playwright MCP | COMPLETADO Y VERIFICADO | Página web y tres capturas de GitHub. |
| Marcar como pendientes las capturas gráficas no automatizables | COMPLETADO Y VERIFICADO | El índice declara el uso de `ftplib.FTP_TLS` como cliente real. |
| Crear `evidencias/indice.md` relacionando requisito, registro y captura | COMPLETADO Y VERIFICADO | Índice actualizado con enlaces a registros y capturas existentes. |

## Permisos y seguridad

- No se borrarán máquinas virtuales ni archivos ajenos al proyecto sin autorización.
- No se cambiará la configuración global de red/DNS de Windows sin autorización.
- No se instalará software nuevo en Windows sin autorización.
- No se publicarán archivos en GitHub ni se invitarán colaboradores sin autorización.
- No se usarán privilegios elevados en el anfitrión sin autorización.
- No se desactivarán mecanismos de seguridad de Windows.
- Las contraseñas de laboratorio no se mostrarán en registros ni en argumentos visibles de procesos.
