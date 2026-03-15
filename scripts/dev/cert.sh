#!/usr/bin/env bash

set -e
source "$(dirname "$(realpath "$0")")/../common.sh"

check_triggered_by_make
check_env dev

openssl req -quiet -x509 -newkey rsa:4096 -keyout reverseproxy/dev-key.pem \
  -out reverseproxy/dev-cert.pem -days 365 -nodes \
  -subj "/C=TW/ST=TW/L=TW/O=TW/OU=TW/CN=TW/emailAddress=TW"

printf "${GREEN} ✔ Certificates generated${RESET}\n"
