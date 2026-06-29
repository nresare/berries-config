#!/usr/bin/env bash

set -euo pipefail

radosgw-admin caps add \
  --rgw-realm berries \
  --uid iam-admin \
  --caps "roles=*;oidc-provider=*;user-policy=*"
