#!/usr/bin/env python3
"""Pruebas reales del servidor FTPS de la práctica.

Las contraseñas se leen de la entrada estándar (una por línea) para que no
aparezcan en argumentos de proceso, historial ni registros.
"""
import io
import ssl
import sys

import ftplib
from cryptography import x509
from cryptography.hazmat.backends import default_backend

HOST = "ftp.raul.test"
resultados = []


def registrar(descripcion, condicion, detalle=""):
    estado = "OK  " if condicion else "FALLO"
    resultados.append(condicion)
    linea = f"{estado} {descripcion}"
    if detalle:
        linea += f" -> {detalle}"
    print(linea)


def contexto():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE  # Certificado autofirmado de la práctica.
    return ctx


def conectar_tls():
    ftp = ftplib.FTP_TLS(context=contexto(), timeout=20)
    ftp.connect(HOST, 21)
    ftp.auth()
    return ftp


def main():
    ana_pass = sys.stdin.readline().rstrip("\r\n")
    juan_pass = sys.stdin.readline().rstrip("\r\n")
    if not ana_pass or not juan_pass:
        print("FALTO: se necesitan dos contraseñas por stdin")
        return 1

    # 1. Resolución y certificado presentado por el servidor.
    ftp = conectar_tls()
    print("Servidor conectado por nombre:", HOST)
    try:
        der = ftp.sock.getpeercert(binary_form=True)
        cert = x509.load_der_x509_certificate(der, default_backend())
        cn = cert.subject.rfc4514_string()
        san = cert.extensions.get_extension_for_class(
            x509.SubjectAlternativeName
        ).value.get_values_for_type(x509.DNSName)
        registrar("Certificado TLS con CN ftp.raul.test", "CN=ftp.raul.test" in cn, cn)
        registrar(
            "SAN incluye ftp.raul.test",
            "ftp.raul.test" in san,
            ", ".join(san),
        )
    except Exception as exc:  # pragma: no cover - diagnóstico
        registrar("Lectura del certificado TLS", False, type(exc).__name__)
    finally:
        ftp.quit()

    # 2. ana: login, acceso a /var/www/html y subida de index.html.
    ftp = conectar_tls()
    try:
        ftp.login("ana", ana_pass)
        ftp.prot_p()
        registrar("Autenticación TLS de ana", True)
        ftp.cwd("/var/www/html")
        registrar("ana accede a /var/www/html", True, ftp.pwd())
        contenido = (
            "<!doctype html>\n<html lang='es'>\n<head><meta charset='utf-8'>"
            "<title>Servidor web del proyecto</title></head>\n<body>\n"
            "<h1>Servidor web de raul.test</h1>\n"
            "<p>Pagina subida por ana mediante FTPS explicito.</p>\n"
            "</body>\n</html>\n"
        ).encode("utf-8")
        ftp.storbinary("STOR index.html", io.BytesIO(contenido))
        registrar("Subida de index.html por ana", True, f"{len(contenido)} bytes")
    except Exception as exc:
        registrar("Pruebas de ana", False, f"{type(exc).__name__}: {exc}")
    finally:
        try:
            ftp.quit()
        except Exception:
            pass

    # 3. juan: autenticación y jaula en su directorio personal.
    ftp = conectar_tls()
    try:
        ftp.login("juan", juan_pass)
        ftp.prot_p()
        registrar("Autenticación TLS de juan", True)
        cwd = ftp.pwd()
        registrar("juan queda enjaulado en /", cwd == "/", f"pwd={cwd}")
        try:
            ftp.cwd("/var/www/html")
            registrar("juan NO puede salir de su jaula", False)
        except ftplib.all_errors:
            registrar("juan NO puede salir de su jaula", True)
    except Exception as exc:
        registrar("Pruebas de juan", False, f"{type(exc).__name__}: {exc}")
    finally:
        try:
            ftp.quit()
        except Exception:
            pass

    # 4. Acceso anónimo rechazado.
    ftp = conectar_tls()
    try:
        ftp.login()
        registrar("Acceso anónimo rechazado", False)
    except ftplib.all_errors:
        registrar("Acceso anónimo rechazado", True)
    finally:
        try:
            ftp.quit()
        except Exception:
            pass

    # 5. Conexión sin cifrar rechazada para usuario local.
    ftp = ftplib.FTP(HOST, timeout=20)
    try:
        ftp.login("ana", ana_pass)
        registrar("Conexión sin TLS rechazada", False)
    except ftplib.all_errors:
        registrar("Conexión sin TLS rechazada", True)
    finally:
        try:
            ftp.quit()
        except Exception:
            pass

    fallos = resultados.count(False)
    print(f"\nResumen: {len(resultados) - fallos} correctas, {fallos} fallidas.")
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
