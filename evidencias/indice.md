# Índice de evidencias — Práctica FTP

Generado: 2026-11-22 17:15 (hora local)

## Procedimiento seguido

1. Ejecutar los comandos de cada apartado y guardar la salida real en `evidencias/`.
2. Comprobar el estado de cada apartado con la propia salida de los comandos.
3. Abrir una ventana visible con esa salida real y usar `capturar.ps1` para guardar la captura en `evidencias/capturas/`.
4. Usar Playwright MCP para las capturas de páginas web (GitHub y el servidor Apache).
5. No capturar contraseñas, tokens ni información sensible.

`capturar.ps1` no se ha modificado. Las capturas de escritorio son imágenes reales
obtenidas con `CopyFromScreen` a partir de ventanas abiertas para mostrar la salida
de comandos ejecutados de verdad. Las capturas web son capturas reales del
navegador controlado por Playwright MCP.

Durante la auditoría final se normalizó la codificación de los registros: se
eliminaron caracteres NUL de tres logs y se repararon las secuencias mal
interpretadas por la consola. El contenido de las salidas es el mismo; solo se
corrigió la representación de los caracteres. También se actualizaron seis
referencias a capturas regeneradas con otro nombre y se añadió `EXIT_CODE` a
esos seis registros.

## Comprobaciones iniciales del entorno

| Apartado | Comprobación | Registro | Captura |
|---|---|---|---|
| 01 | Sistema operativo y PowerShell | [registro](registros/01_sistema_operativo_powershell.log) | [captura](capturas/20261122_171322-entorno_comprobaciones.png) |
| 02 | Ruta del proyecto | [registro](registros/02_ruta_proyecto.log) | [captura](capturas/20261122_171322-entorno_comprobaciones.png) |
| 03 | Versión de Vagrant | [registro](registros/03_vagrant.log) | [captura](capturas/20261122_171322-entorno_comprobaciones.png) |
| 04 | Versión de VirtualBox | [registro](registros/04_virtualbox.log) | [captura](capturas/20261122_171322-entorno_comprobaciones.png) |
| 05 | Git y SSH | [registro](registros/05_git_ssh.log) | [captura](capturas/20261122_171322-entorno_comprobaciones.png) |
| 06 | Contenido de la carpeta del proyecto | [registro](registros/06_carpeta_enlaces_archivos.log) | [captura](capturas/20261122_171322-entorno_comprobaciones.png) |

Nota: en la primera pasada `ssh -V` escribió su salida en stderr y PowerShell 5.1
con `$ErrorActionPreference = 'Stop'` lanzó un `NativeCommandError`. Se corrigió
leyendo la salida con `cmd /c "ssh -V 2>&1"`. Las pruebas 1 a 4 no se repitieron.

## Ejecución de la práctica

| Apartado | Comprobación | Registro | Captura | Resultado |
|---|---|---|---|---|
| Vagrant | `vagrant up` de las tres VMs | [registro](vagrant/vagrant_up.log) | [captura](capturas/20261122_171257-vagrant_status_real.png) | `EXIT_CODE=0` |
| Vagrant | Aprovisionamiento del nodo Ansible | [registro](vagrant/vagrant_provision_ansible.log) | [captura](capturas/20261122_171322-entorno_comprobaciones.png) | `EXIT_CODE=0` |
| Ansible | Instalación de `community.crypto` | [registro](ansible/instalar_coleccion.log) | [captura](capturas/20261122_171329-ansible_nodo_control.png) | `EXIT_CODE=0` |
| Ansible | Inventario, ping y elevación | [registro](ansible/comprobaciones_iniciales.log) | [captura](capturas/20261122_171329-ansible_nodo_control.png) | Todas las comprobaciones exitosas |
| Ansible | Ajuste de versión y `syntax-check` | [registro](ansible/collection_compatible_y_sintaxis.log) | [captura](capturas/20261122_171329-ansible_nodo_control.png) | `community.crypto` 2.26.9 |
| Ansible | Reverificación final de sintaxis | [registro](ansible/reverificacion_sintaxis.log) | — | 3 playbooks OK, `EXIT_CODE=0` |
| DNS | Ejecución de `dns/dns.yml` | [registro](dns/ansible_playbook_dns.log) | [captura](capturas/20261122_171336-dns_pruebas_registros.png) | `ok=10 changed=5 failed=0` |
| DNS | Pruebas directas e inversas | [registro](dns/pruebas_registros_dns.log) | [captura](capturas/20261122_171336-dns_pruebas_registros.png) | 8/8 correctas |
| DNS | Reverificación final en vivo | [registro](dns/reverificacion_final.log) | — | 8/8 correctas, `EXIT_CODE=0` |
| DNS | Resolvers internos de las VMs | [registro](dns/configurar_resolvers_internos.log) | [captura](capturas/20261122_171336-dns_pruebas_registros.png) | `EXIT_CODE=0` |
| Web | Despliegue de Apache | [registro](web/ansible_playbook_web.log) | [captura](capturas/20261122_171342-web_prueba_curl.png) | `ok=6 changed=3 failed=0` |
| Web | Prueba HTTP desde el nodo | [registro](web/prueba_curl_web.log) | [captura](capturas/20261122_171342-web_prueba_curl.png) | `EXIT_CODE=0` |
| Web | Prueba HTTP desde el anfitrión | [registro](web/prueba_curl_host.log) | [captura web](capturas/web_playwright_raul_test.png) | `HTTP/1.1 200 OK`, 221 bytes |
| FTP | Ejecución de `ftp/ftp.yml` | [registro](ftp/ansible_playbook_ftp.log) | [captura](capturas/20261122_171349-ftp_servicio_certificado.png) | `ok=18 changed=2 failed=0` |
| FTP | Servicio y certificado | [registro](ftp/verificacion_servicio_y_certificado.log) | [captura](capturas/20261122_171349-ftp_servicio_certificado.png) | CN `ftp.raul.test` |
| FTP | Pruebas reales con `ftplib.FTP_TLS` | [registro](ftp/pruebas_ftps.log) | [captura](capturas/20261122_171355-ftp_resumen_pruebas.png) | 10 correctas, 0 fallidas |
| FTP | Reverificación final en vivo | [registro](ftp/reverificacion_final.log) | — | 10 correctas, 0 fallidas, `EXIT_CODE=0` |
| FTP | Publicación de `index.html` subido por `ana` | [registro](ftp/verificacion_publicacion_ana.log) | [captura web](capturas/web_playwright_raul_test.png) | Texto visible en la web |
| GitHub | Repositorio creado | [registro](github/verificar_cuenta.log) | [captura](capturas/github_01_repositorio_creado.png) | Cuenta verificada |
| GitHub | Issues y sub-issues | [registros](github/creacion_issues.log) | [captura](capturas/github_03_issues.png) | 40 issues creadas, 33 sub-issues vinculadas |
| GitHub | Tablero de proyectos | [registro](github/creacion_project.log) | [captura](capturas/github_02_proyecto_tablero.png) | Por hacer / En progreso / Hecho, 40 issues en Hecho |
| GitHub | Cierre de issues y estado final del tablero | [registro](github/cierre_issues_tablero.log) | [captura](capturas/github_02_proyecto_tablero.png) | 41 cerradas (40 del enunciado + 1 de prueba), 0 abiertas |
| GitHub | Proyecto vinculado al repositorio | [registro](github/creacion_project.log) | [captura](capturas/github_04_proyecto_vinculado.png) | 1 proyecto: `Practica FTP Vagrant Ansible` |

## Capturas disponibles

- `20261122_171257-vagrant_status_real.png` — salida real de `vagrant status`.
- `20261122_171322-entorno_comprobaciones.png` — versiones reales del entorno.
- `20261122_171329-ansible_nodo_control.png` — inventario y ping de Ansible.
- `20261122_171336-dns_pruebas_registros.png` — pruebas DNS reales.
- `20261122_171342-web_prueba_curl.png` — página servida por Apache.
- `20261122_171349-ftp_servicio_certificado.png` — servicio y certificado TLS.
- `20261122_171355-ftp_resumen_pruebas.png` — resumen de las 10 pruebas FTPS.
- `web_playwright_raul_test.png` — página `http://www.raul.test/` en el navegador.
- `github_01_repositorio_creado.png`, `github_02_proyecto_tablero.png`, `github_03_issues.png`,
  `github_04_proyecto_vinculado.png`.

## Incidentes documentados

- **Bloqueo de `apt-get update`**: conexiones HTTPS en `CLOSE-WAIT`; se añadieron
  tiempos de espera acotados a `web.yml` y `ftp.yml`. Registro:
  [apt_update_diagnostico.log](web/apt_update_diagnostico.log).
- **Hashes SHA-512-crypt incorrectos**: `mkpasswd` conservaba el CR de la entrada
  de Windows; se regeneraron con Python `crypt`. Registro:
  [diagnostico_login.log](ftp/diagnostico_login.log).
- **`syntax-check` de FTP sin vault secret**: registro
  [provision_final_y_sintaxis.log](ansible/provision_final_y_sintaxis.log), resuelto
  pasando `--vault-password-file`.
- **Codificación de títulos de issues**: la primera creación mediante PowerShell 5.1
  produjo caracteres mal codificados; se corrigieron con solicitudes UTF-8. Registros:
  [creacion_issues.log](github/creacion_issues.log) y
  [correccion_issues.log](github/correccion_issues.log).

## Notas

- Los registros `.log` contienen la salida real redirigida desde la ejecución de los comandos.
- Ninguna captura ni registro contiene contraseñas, tokens ni claves privadas.
- `nslookup` consulta DNS directamente y no usa el archivo `hosts` de Windows; por eso
  la comprobación de resolución desde el anfitrión se hizo con `curl.exe` y el
  navegador, que sí usan `hosts`.
