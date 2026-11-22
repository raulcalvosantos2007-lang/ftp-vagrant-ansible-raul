# Informe final — Práctica de FTP con Vagrant y Ansible

**Alumno:** Raúl Calvo Santos  
**Fecha:** 2026-11-22  
**Repositorio:** `https://github.com/raulcalvosantos2007-lang/ftp-vagrant-ansible-raul`  
**Tablero:** GitHub Project `Practica FTP Vagrant Ansible`  
**Dominio:** `raul.test`

## 1. Resumen ejecutivo

La práctica se ha ejecutado íntegramente en el entorno real del alumno: tres
máquinas VirtualBox gestionadas por Vagrant, aprovisionadas desde un nodo de
control Ansible. Los servicios DNS, web y FTP seguro están operativos y han sido
verificados con comandos reales y capturas auténticas.

| Bloque | Resultado | Evidencia principal |
|---|---|---|
| Infraestructura Vagrant | 3/3 VM creadas | `evidencias/vagrant/vagrant_up.log` |
| Ansible | Ping y elevación correctos en 2 nodos | `evidencias/ansible/comprobaciones_iniciales.log` |
| DNS | 8/8 pruebas correctas | `evidencias/dns/pruebas_registros_dns.log` |
| Web | HTTP 200, 221 bytes | `evidencias/web/prueba_curl_host.log` |
| FTPS | 10/10 pruebas correctas | `evidencias/ftp/pruebas_ftps.log` |
| GitHub | Repo, 40 issues cerradas, 33 sub-issues, tablero en Hecho | `evidencias/capturas/github_0*.png` |

## 2. Cumplimiento de los apartados del enunciado

### Licencia
- [x] Licencia MIT con texto completo en `LICENSE`.

### README
- [x] Nombre del alumno y dirección del repositorio.
- [x] Objetivo del proyecto.
- [x] Herramientas utilizadas.
- [x] Instrucciones iniciales de uso.

### Vagrant
- [x] Tres máquinas `debian/bookworm64`: `dns` (`192.168.57.5`), `negocio`
  (`192.168.57.7`) y `ansible` (`192.168.57.6`).
- [x] `script/ansible.sh` prepara el nodo de control.
- [x] `requirements.yml` fija `community.crypto` 2.26.9.

### Ansible
- [x] `ansible.cfg` documentado, con advertencia de que no es apto para producción.
- [x] `inventory.yml` en YAML con los dos hosts gestionados.

### DNS
- [x] Zona directa `raul.test` e inversa `192.168.57.in-addr.arpa`.
- [x] Registros A para `dns`, `ansible` y `negocio`.
- [x] CNAME `www` y `ftp` hacia `negocio`.
- [x] PTR para las tres direcciones.
- [x] Script de pruebas con 8 comprobaciones correctas.
- [x] Playbook `dns/dns.yml` ejecutado: `ok=10 changed=5 failed=0`.

### Web
- [x] Playbook `web/web.yml` y handler de reinicio.
- [x] Apache instalado y activo, página servida.
- [x] Prueba con `curl` desde el nodo y desde el anfitrión.

### FTP
- [x] Playbook `ftp/ftp.yml` ejecutado: `ok=18 changed=2 failed=0`.
- [x] `vsftpd` en modo independiente, solo IPv4, sin anónimo, solo usuarios locales.
- [x] Usuarios `juan` y `ana` con contraseñas cifradas en Ansible Vault.
- [x] `juan` enjaulado; `ana` accede a `/var/www/html` y sube `index.html`.
- [x] TLS obligatorio con certificado autofirmado CN/SAN `ftp.raul.test`.
- [x] Prueba real con `ftplib.FTP_TLS`: 10/10.

### GitHub
- [x] Repositorio creado bajo la cuenta correcta y cambios publicados.
- [x] 7 issues principales y 33 sub-issues del enunciado, adaptadas a `raul.test`.
- [x] Tablero con columnas **Por hacer**, **En progreso** y **Hecho**.
- [x] Todas las issues cerradas: 7 por `Fixes #1..#7` en el commit `fc45611` y 33
  mediante la API; el tablero muestra 40 tarjetas en **Hecho**.
  Registro: `evidencias/github/cierre_issues_tablero.log`.
- [x] Sin invitación a colaboradores externos (decisión del usuario).

## 3. Flujo verificado de extremo a extremo

1. El usuario `ana` se autenticó por FTPS en `ftp.raul.test`.
2. Subió `index.html` a `/var/www/html` (221 bytes).
3. Apache publicó ese mismo archivo.
4. `curl.exe http://www.raul.test/` desde Windows devolvió `HTTP/1.1 200 OK` y el
   texto `<p>Pagina subida por ana mediante FTPS explicito.</p>`.
5. El navegador controlado por Playwright mostró la misma página
   (`evidencias/capturas/web_playwright_raul_test.png`).

## 4. Resolución de nombres en el anfitrión

No se cambió el DNS global de Windows. Con autorización del usuario se añadieron
estas líneas a `C:\Windows\System32\drivers\etc\hosts`:

```text
192.168.57.5 dns.raul.test
192.168.57.6 ansible.raul.test
192.168.57.7 negocio.raul.test www.raul.test ftp.raul.test
```

`nslookup` consulta directamente al servidor DNS configurado y no usa este
archivo, por lo que no es la prueba adecuada en el anfitrión; la resolución se
comprobó con `curl.exe` y con el navegador, que sí lo utilizan.

## 5. Inconsistencias del enunciado

1. Se menciona «las dos máquinas» pero la arquitectura define tres; se aplicó la
   arquitectura de tres máquinas.
2. En `script/ansible.sh` hay un comentario con `chown ... inventory.yml` donde
   debería decir `requirements.yml`; se documentó y se corrigió en el script.
3. La prosa FTP indica `/etc/ssl/equipo/vsftpd.crt`, pero el playbook construye
   `/etc/ssl/<dominio>/<dominio>.{crt,key}`. Se mantuvo el esquema del playbook con
   `cert_dir: /etc/ssl/ftp` y `domain_name: raul.test`.
4. La prosa pide CN y SAN `ftp.raul.test`, mientras el playbook propone
   `common_name: "{{ domain_name }}"`. Se fijó `common_name: ftp.raul.test` y SAN
   `ftp.raul.test`, `raul.test` y `www.raul.test`.
5. El documento adicional sobre opciones de `vsftpd` no está en los archivos
   entregados. No se ha consultado ni se afirma lo contrario; solo se usó
   documentación oficial para los huecos necesarios
   (`documentacion/vsftpd_opciones.md`).

## 6. Seguridad y buenas prácticas

- Contraseñas y clave del vault fuera de registros, capturas y repositorio. El HTML
  original del enunciado contiene la contraseña de ejemplo del vault; se conserva en
  local pero está excluido mediante `.gitignore` y no se versiona.
- `ftp/vars/vault.yml` cifrado; `vault_pass.txt` y claves privadas ignorados por Git.
- `host_key_checking = False` y usuario `vagrant` solo para el laboratorio.
- El certificado es autofirmado: los clientes deben confiar en él explícitamente.

## 7. Evidencias y documentación

- Índice completo: `evidencias/indice.md`.
- Memoria detallada: `documentacion/memoria.md`.
- Plan de trabajo con estados: `documentacion/PLAN_DE_TRABAJO.md`.
- Opciones de `vsftpd`: `documentacion/vsftpd_opciones.md`.
- Capturas reales: `evidencias/capturas/`.

No se han generado imágenes artificiales ni textos superpuestos. Las únicas
capturas de cliente FTP son las del servicio y el resumen de pruebas; el cliente
real utilizado fue `ftplib.FTP_TLS`, cuya salida está en `evidencias/ftp/pruebas_ftps.log`.

## 8. Auditoría final

Se repitieron las comprobaciones principales sobre el entorno ya desplegado:

| Comprobación | Resultado | Registro |
|---|---|---|
| DNS directo e inverso | 8/8 correctas | `evidencias/dns/reverificacion_final.log` |
| `syntax-check` de los 3 playbooks | 3/3 correctos | `evidencias/ansible/reverificacion_sintaxis.log` |
| FTPS con cliente real | 10/10 correctas | `evidencias/ftp/reverificacion_final.log` |
| Web desde el anfitrión | HTTP 200, 221 bytes | `evidencias/web/prueba_curl_host.log` |
| Estado de los servicios | `apache2` y `vsftpd` activos | comprobación con `systemctl is-active` |
| Repositorio | HEAD local = HEAD remoto, 73 ficheros, 41 issues cerradas, 33 sub-issues | API de GitHub |

Además se revisaron los 33 registros `.log`: ninguno contiene caracteres NUL,
secuencias mal codificadas ni referencias a capturas inexistentes, y todos
incluyen `EXIT_CODE`.

La auditoría detectó que el historial inicial contenía el enunciado original con
la contraseña de ejemplo del vault. Con autorización del usuario se reescribió
el historial: el repositorio remoto tiene ahora un único commit limpio, sin el
enunciado ni ninguna credencial en texto plano. El tablero y las issues no se
vieron afectados.
