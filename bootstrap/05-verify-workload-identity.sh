#!/usr/bin/env bash

set -euo pipefail

: "${RGW_ENDPOINT:?Set RGW_ENDPOINT to the forwarded RGW endpoint}"

token_file="$(mktemp)"
trap 'rm -f "$token_file"' EXIT

kubectl -n default create token default \
  --audience sts.amazonaws.com >"$token_file"

aws \
  --endpoint-url "$RGW_ENDPOINT" \
  sts assume-role-with-web-identity \
  --role-arn arn:aws:iam:::role/k8s-workload-s3 \
  --role-session-name test \
  --web-identity-token "file://$token_file"
