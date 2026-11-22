#!/usr/bin/env bash
# Comprobaciones directas e inversas contra el servidor DNS de la práctica.
set -eu

DNS_SERVER="192.168.57.5"
FALLOS=0

comprobar() {
    descripcion="$1"
    esperado="$2"
    shift 2
    real="$("$@" | tr -d '\r' | head -n 1)"
    if [ "$real" = "$esperado" ]; then
        printf 'OK   %-42s -> %s\n' "$descripcion" "$real"
    else
        printf 'FALLO %-41s -> esperado "%s", obtenido "%s"\n' "$descripcion" "$esperado" "$real"
        FALLOS=$((FALLOS + 1))
    fi
}

comprobar "A dns.raul.test" "192.168.57.5" \
    dig +short "@${DNS_SERVER}" dns.raul.test A
comprobar "A ansible.raul.test" "192.168.57.6" \
    dig +short "@${DNS_SERVER}" ansible.raul.test A
comprobar "A negocio.raul.test" "192.168.57.7" \
    dig +short "@${DNS_SERVER}" negocio.raul.test A
comprobar "CNAME www.raul.test" "negocio.raul.test." \
    dig +short "@${DNS_SERVER}" www.raul.test CNAME
comprobar "CNAME ftp.raul.test" "negocio.raul.test." \
    dig +short "@${DNS_SERVER}" ftp.raul.test CNAME
comprobar "PTR 192.168.57.5" "dns.raul.test." \
    dig +short "@${DNS_SERVER}" -x 192.168.57.5
comprobar "PTR 192.168.57.6" "ansible.raul.test." \
    dig +short "@${DNS_SERVER}" -x 192.168.57.6
comprobar "PTR 192.168.57.7" "negocio.raul.test." \
    dig +short "@${DNS_SERVER}" -x 192.168.57.7

if [ "$FALLOS" -ne 0 ]; then
    printf '\n%s comprobaciones DNS fallidas.\n' "$FALLOS"
    exit 1
fi

printf '\nTodas las comprobaciones DNS han terminado correctamente.\n'
