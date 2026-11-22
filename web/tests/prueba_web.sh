#!/usr/bin/env bash
# Comprueba que Apache sirve la página publicada a través del nombre DNS.
set -eu

URL="http://www.raul.test/"
body="$(curl -fsS "$URL")"

printf '%s\n' "$body"
printf '%s\n' "$body" | grep -Fq '<h1>Servidor web de raul.test</h1>'
printf '\nLa página %s responde correctamente.\n' "$URL"
