# Memoria de la práctica: FTP con Vagrant y Ansible como nodo controlador

**Alumno:** Raúl Calvo Santos  
**Asignatura:** Despliegue de Aplicaciones Web (2.º DAW)  
**Dominio de la práctica:** `raul.test`  
**Repositorio:** `https://github.com/raulcalvosantos2007-lang/ftp-vagrant-ansible-raul`

## 1. Objetivo

Desplegar automáticamente un entorno formado por tres máquinas virtuales Debian
Bookworm y verificar, con comandos reales, los servicios de DNS, web y FTP seguro.
La práctica sirve además para usar GitHub como sistema de control de versiones,
gestión de incidencias y planificación de tareas.

## 2. Arquitectura implementada

| Máquina | Nombre | IP | Función |
|---|---|---|---|
| `dns` | `dns.raul.test` | `192.168.57.5` | BIND9, zonas directa e inversa de `raul.test` |
| `ansible` | `ansible.raul.test` | `192.168.57.6` | Nodo controlador de Ansible |
| `negocio` | `negocio.raul.test` | `192.168.57.7` | Apache2 y vsftpd con TLS |

El enunciado usa `equipo.test` como dominio de ejemplo; se ha sustituido por
`raul.test`, según las instrucciones recibidas. Se mantiene la estructura de tres
máquinas definida en el Vagrantfile del enunciado, a pesar de que una frase del
texto hable de «dos máquinas».

## 3. Herramientas y versiones comprobadas

| Herramienta | Versión comprobada |
|---|---|
| Windows | 11 Pro, compilación `10.0.26300` |
| PowerShell | `5.1.26100.9818` |
| Vagrant | `2.4.9` |
| Oracle VirtualBox | `7.2.6r172322` |
| Git | `2.56.0.windows.2` |
| OpenSSH | `OpenSSH_for_Windows_9.5p2, LibreSSL 3.8.2` |
| Box | `debian/bookworm64 (virtualbox, 12.20250126.1, (amd64))` |
| Ansible Core | `2.14.18` (instalado en la VM `ansible`) |
| `community.crypto` | `2.26.9` (versión compatible con Ansible 2.14) |
| Apache | `2.4.71 (Debian)` |
| BIND9 y vsftpd | paquetes de Debian Bookworm instalados por Ansible |

Las comprobaciones iniciales están en `evidencias/registros/` y en la captura
`evidencias/capturas/20261122_171322-entorno_comprobaciones.png`.

## 4. Desarrollo de la práctica

### 4.1 Preparación del entorno

Se verificaron la RAM disponible (15,28 GB totales, 5,45 GB libres), la
virtualización activada y la ausencia de conflictos con la red host-only. La red
`192.168.57.1` pertenece al adaptador host-only n.º 2 de VirtualBox, no a otra VM.

Se creó el `Vagrantfile` con las tres máquinas y se validó con `vagrant validate`.
Después se ejecutó `vagrant up`: las tres máquinas se crearon correctamente y el
aprovisionamiento del nodo Ansible terminó con `EXIT_CODE=0`
(`evidencias/vagrant/vagrant_up.log`).

`script/ansible.sh` instala `ansible`, `ansible-lint`, `whois`, `dnsutils` y
`curl`, copia las claves privadas de `dns` y `negocio` dentro de la VM y ajusta
los permisos del fichero de contraseña del vault. Las claves privadas y
`vault_pass.txt` están ignorados por Git y nunca se han subido al repositorio.

### 4.2 Configuración de Ansible

`ansible.cfg` usa el inventario YAML, el usuario `vagrant`, claves privadas por
host y desactiva `host_key_checking`. Esta última opción es aceptable en un
laboratorio aislado, pero **no es apta para producción**; queda documentada en el
README y en este informe.

Comprobaciones ejecutadas desde la VM `ansible` (`evidencias/ansible/comprobaciones_iniciales.log`):

- `ansible-inventory --graph` → `dns` y `negocio`.
- `ansible all -m ping` → `pong` en ambas máquinas.
- `ansible all -b -a "uptime"` → salida correcta en ambas máquinas.

Los tres playbooks pasaron `ansible-playbook --syntax-check`.

### 4.3 Servidor DNS

Se crearon los ficheros de zona directa e inversa y la configuración de BIND9 en
`dns/files/`, junto con `dns/dns.yml` y `dns/tests/pruebas_dns.sh`.

Ejecución del playbook: `ok=10 changed=5 failed=0`
(`evidencias/dns/ansible_playbook_dns.log`).

Pruebas de registros: 8/8 correctas
(`evidencias/dns/pruebas_registros_dns.log`):

- A `dns.raul.test` → `192.168.57.5`
- A `ansible.raul.test` → `192.168.57.6`
- A `negocio.raul.test` → `192.168.57.7`
- CNAME `www.raul.test` y `ftp.raul.test` → `negocio.raul.test.`
- PTR de las tres direcciones → los nombres esperados

Además se configuraron los resolvers internos de las tres VMs para usar
`192.168.57.5`. En el anfitrión Windows no se cambió el DNS global: se añadieron
tres entradas al archivo `hosts`, previa autorización del usuario, para que el
navegador y `curl` resolvieran los nombres.

### 4.4 Servidor web

`web/web.yml` instala Apache, publica `web/files/index.html`, habilita el servicio
y reinicia Apache mediante un handler cuando cambia la página.

Ejecución: `ok=6 changed=3 failed=0`
(`evidencias/web/ansible_playbook_web.log`).

La comprobación desde el nodo Ansible y desde el anfitrión devuelve `HTTP/1.1 200 OK`
y 221 bytes, con el texto `<p>Pagina subida por ana mediante FTPS explicito.</p>`
(`evidencias/web/prueba_curl_web.log` y `evidencias/web/prueba_curl_host.log`).
La página también se capturó con Playwright MCP en
`evidencias/capturas/web_playwright_raul_test.png`.

### 4.5 Servidor FTP seguro

`ftp/ftp.yml` instala `vsftpd`, crea los usuarios `juan` y `ana` con hashes
SHA-512-crypt cifrados en `ftp/vars/vault.yml`, configura el jaulado, el
directorio web de `ana` y el certificado autofirmado generado con
`community.crypto`.

- Certificado: CN `ftp.raul.test`; SAN `ftp.raul.test`, `raul.test`, `www.raul.test`.
  Archivos: `/etc/ssl/ftp/raul.test.crt` y `.key`.
- `juan` queda enjaulado en su directorio personal; `ana` es la excepción y
  trabaja en `/var/www/html`.
- Acceso anónimo y conexiones sin TLS rechazados.
- Ejecución del playbook: `ok=18 changed=2 failed=0`
  (`evidencias/ftp/ansible_playbook_ftp.log`).

Las pruebas reales se hicieron con `ftp/tests/prueba_ftp.py`, un cliente Python
que usa `ftplib.FTP_TLS` y lee las contraseñas por stdin, de modo que no aparecen
en argumentos, registros ni capturas. Resultado: **10 correctas, 0 fallidas**
(`evidencias/ftp/pruebas_ftps.log`). El cliente se conectó por el nombre
`ftp.raul.test`, verificó CN y SAN, comprobó los accesos de `ana` y `juan`, la
subida de `index.html` (221 bytes), el rechazo anónimo y el rechazo de FTP plano.
La página publicada se verificó después por HTTP, confirmando el flujo completo
DNS → FTPS → Apache.

Las opciones de `vsftpd` y su justificación están en
`documentacion/vsftpd_opciones.md`. El documento adicional sobre opciones de
`vsftpd` mencionado en el enunciado **no está incluido** en los archivos
entregados; no se ha consultado y no se afirma lo contrario. Solo se usó
documentación oficial para completar los huecos necesarios.

### 4.6 GitHub, issues y tablero

Se verificó la cuenta `raulcalvosantos2007-lang` y se creó el repositorio
`ftp-vagrant-ansible-raul`, público y con descripción. Se crearon 7 issues
principales (licencia, README, Vagrant, Ansible, DNS, web y FTP) y 33 sub-issues
con el texto del enunciado adaptado a `raul.test`, todas vinculadas a su issue
padre mediante la API de sub-issues. Quedó abierta una issue de prueba de
codificación, cerrada posteriormente. No se invitó a ningún colaborador externo,
según la decisión del usuario.

Se creó el GitHub Project `Practica FTP Vagrant Ansible` con plantilla Kanban y
las 40 issues del enunciado importadas. Las opciones de estado se renombraron a
**Por hacer**, **En progreso** y **Hecho**, y se eliminaron las opciones sobrantes
de la plantilla. Hay capturas del repositorio, del tablero y de las issues en
`evidencias/capturas/`.

El commit `fc45611`, publicado con `Fixes #1..#7`, cerró automáticamente las 7
issues principales. Las 33 restantes se cerraron con la API de GitHub para dejar
el tablero totalmente terminado: 40 tarjetas en **Hecho** y ninguna en **Por hacer**
ni **En progreso** (`evidencias/github/cierre_issues_tablero.log`). La issue de
prueba de codificación también quedó cerrada, sumando 41 issues cerradas en total.

## 5. Incidencias y soluciones

1. **`apt-get update` colgado** durante el despliegue web (26 minutos, sockets HTTPS
   en `CLOSE-WAIT`). Se detuvo el proceso, se comprobó que con
   `Acquire::http/https::Timeout=15`, `Acquire::Retries=1` y
   `Acquire::ForceIPv4=true` termina en 10 segundos, y se añadió esa invocación
   con `timeout 240` a `web.yml` y `ftp.yml`. Ansible 2.14 no admite
   `args: timeout` en el módulo `command`, por lo que se usa el binario `timeout`.
2. **`curl: command not found`** en la VM Ansible. Se añadió `curl` a
   `script/ansible.sh` y se instaló en la máquina ya creada.
3. **Hashes SHA-512-crypt incorrectos**. `mkpasswd --method=sha-512` conservaba el
   carácter `\r` de la entrada enviada desde Windows, provocando `530 Login
   incorrect`. Se regeneraron con Python `crypt.mksalt()` leyendo las contraseñas
   por stdin y recortando CRLF, se cifró de nuevo el vault y las 10 pruebas pasaron.
4. **`syntax-check` de FTP sin secreto de vault**. La primera comprobación falló con
   `ERROR! Attempting to decrypt but no vault secrets found`; se repitió con
   `--vault-password-file` y terminó correctamente.
5. **Codificación de títulos de issues**. La creación mediante PowerShell 5.1 envió
  en su momento los caracteres españoles como ASCII, produciendo títulos corruptos. Se
   corrigieron todos con solicitudes PATCH en UTF-8 y se vincularon las sub-issues
   con el identificador numérico correcto (los IDs de GitHub exceden Int32).
6. **Permisos de scripts y elevación**. La política de ejecución de PowerShell
   impide ejecutar `.ps1` directamente; se usó `powershell -ExecutionPolicy Bypass
   -File`. Para modificar el `hosts` de Windows se necesitó un proceso elevado,
   autorizado expresamente por el usuario.
7. **Capturas desaparecidas**. Las capturas iniciales ya no estaban en
   `evidencias/capturas/`; se regeneraron con `capturar.ps1` a partir de ventanas
   reales con salida de comandos. El índice de evidencias refleja solo las
   capturas existentes.

## 6. Seguridad

- Las contraseñas de laboratorio no aparecen en argumentos visibles, registros,
  capturas ni en el repositorio. El HTML original del enunciado incluye la
  contraseña de ejemplo del vault, por lo que se conserva solo en local y está
  excluido del control de versiones mediante `.gitignore`.
- `ftp/vars/vault.yml` está cifrado con Ansible Vault; el fichero sin cifrar no
  existe y `vault_pass.txt` está ignorado por Git.
- Las claves privadas de Vagrant se copian solo dentro de la VM `ansible` y están
  ignoradas por Git.
- `host_key_checking = False` y el usuario `vagrant` con clave conocida son
  simplificaciones del laboratorio; no deben usarse en producción.
- No se ha modificado el DNS global de Windows: se usaron entradas en `hosts`,
  con autorización del usuario.

## 7. Resultado global

Todos los servicios están desplegados y verificados: DNS (8/8), web (HTTP 200 y
página subida por FTPS) y FTPS (10/10). El código, las evidencias y la
documentación están publicados en el repositorio indicado. El detalle de
comprobaciones y capturas se encuentra en `evidencias/indice.md` y el resumen
final en `documentacion/INFORME_FINAL.md`.
