#!/usr/bin/env bash

set -euo pipefail

: "${RGW_ENDPOINT:?Set RGW_ENDPOINT to the forwarded RGW endpoint}"

thumbprint="$(
  curl -s https://letsencrypt.org/certs/isrgrootx1.pem \
    | openssl x509 -fingerprint -sha1 -noout \
    | sed 's/sha1 Fingerprint=//I; s/://g' \
    | tr '[:upper:]' '[:lower:]'
)"

aws \
  --profile rgw-admin \
  --endpoint-url "$RGW_ENDPOINT" \
  iam create-open-id-connect-provider \
  --url https://k8s.noa.re \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list "$thumbprint"
