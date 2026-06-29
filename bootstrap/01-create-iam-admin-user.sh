#!/usr/bin/env bash

set -euo pipefail

radosgw-admin user create \
  --rgw-realm berries \
  --uid iam-admin \
  --display-name "IAM Admin" \
  --gen-access-key \
  --gen-secret
