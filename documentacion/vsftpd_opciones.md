# Opciones de `vsftpd` utilizadas en la práctica

## Documentación disponible

El enunciado menciona un documento adicional con opciones de `vsftpd` que **no
se encuentra entre los archivos entregados**. Por tanto, **no se ha consultado**
y no se afirma lo contrario. Para completar los huecos se ha usado únicamente
documentación oficial:

- Manpage `vsftpd.conf(5)` de Debian Bookworm:
  <https://manpages.debian.org/bookworm/vsftpd/vsftpd.conf.5.en.html>
- Manpage publicada por el proyecto vsftpd:
  <https://security.appspot.com/vsftpd/vsftpd_conf.html>

Fecha de consulta: 2026-11-22.

## Opciones configuradas y motivo

| Opción | Valor | Motivo (según la documentación oficial) |
|---|---|---|
| `listen` / `listen_ipv6` | `YES` / `NO` | Modo independiente sobre IPv4 únicamente. |
| `anonymous_enable` | `NO` | El enunciado exige rechazar el acceso anónimo. |
| `local_enable` | `YES` | Permite autenticar a los usuarios locales `juan` y `ana`. |
| `write_enable` | `YES` | Necesaria para que `ana` pueda subir `index.html`. |
| `local_umask` | `002` | Los archivos nuevos quedan con `0664` (legibles por el grupo `webpublish`, usado por Apache). |
| `file_open_mode` | `0666` | Máscara de creación antes de aplicar `local_umask`. |
| `chroot_local_user` | `YES` | Enjaula por defecto a los usuarios locales en su directorio personal. La manpage advierte de que tiene implicaciones de seguridad. |
| `chroot_list_enable` | `YES` | Activa la lista de excepciones. |
| `chroot_list_file` | `/etc/vsftpd.chroot_list` | Contiene solo a `ana`; con `chroot_local_user=YES` la lista es de usuarios **no** enjaulados. |
| `user_config_dir` | `/etc/vsftpd_user_conf` | Permite sobrescribir opciones por usuario; `/etc/vsftpd_user_conf/ana` fija `local_root=/var/www/html`. |
| `local_root` | `/var/www/html` (solo para `ana`) | Directorio al que vsftpd cambia tras el login local. |
| `ssl_enable` | `YES` | Habilita FTP sobre TLS. |
| `force_local_logins_ssl` | `YES` | Obliga a cifrar también la autenticación. |
| `force_local_data_ssl` | `YES` | Obliga a cifrar el canal de datos. |
| `require_ssl_reuse` | `NO` | Evita incompatibilidades con clientes que no reutilizan la sesión TLS en el canal de datos. |
| `ssl_ciphers` | `HIGH` | Restringe la lista de cifrados permitidos. |
| `rsa_cert_file` / `rsa_private_key_file` | `/etc/ssl/ftp/raul.test.{crt,key}` | Certificado y clave generados por `community.crypto`. |
| `pasv_enable` | `YES` | Habilita el modo pasivo. |
| `pasv_min_port` / `pasv_max_port` | `40000` / `40100` | Rango pasivo acotado. |
| `pasv_address` | `192.168.57.7` | Fuerza la IP anunciada en las respuestas PASV. |

### Observaciones sobre opciones no presentes en la manpage consultada

`allow_writeable_chroot=YES` y `seccomp_sandbox=NO` aparecen en el fichero de
configuración propuesto, pero **no figuran en la manpage oficial consultada**.
Se mantienen de forma explícita porque:

- `allow_writeable_chroot` es necesaria, en versiones que la soportan, para
  que el directorio personal enjaulado de `juan` pueda ser escribible sin que
  vsftpd rechace el login.
- `seccomp_sandbox=NO` evita fallos de arranque del demonio en entornos
  virtualizados con versiones antiguas de vsftpd.

Su efecto se comprobará empíricamente con `vsftpd -v`, el arranque del servicio
y las pruebas reales de `juan`. Si la versión instalada no las admite, se
ajustará la configuración y se documentará el cambio en `memoria.md`.

## Certificado

El enunciado pide que `ftp.raul.test` sea el **CN y también SAN**. El playbook
genera un CSR con `common_name: ftp.raul.test` y SAN `ftp.raul.test`,
`raul.test` y `www.raul.test`. La ruta del certificado usa `raul.test` como
nombre de archivo, coherente con la variable `domain_name` del playbook.
