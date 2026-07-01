#!/usr/bin/env bash

set -euo pipefail

: "${RGW_ENDPOINT:?Set RGW_ENDPOINT to the local RGW endpoint, for example http://localhost:8080}"

aws --profile rgw-admin \
  --endpoint-url "$RGW_ENDPOINT" \
  s3api create-bucket \
  --bucket repo-noa-re
