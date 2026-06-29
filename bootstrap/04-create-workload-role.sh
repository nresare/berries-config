#!/usr/bin/env bash

set -euo pipefail

policy_file="$(mktemp)"
trap 'rm -f "$policy_file"' EXIT

cat >"$policy_file" <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam:::oidc-provider/k8s.noa.re"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "k8s.noa.re:aud": "sts.amazonaws.com",
          "k8s.noa.re:sub": "system:serviceaccount:default:default"
        }
      }
    }
  ]
}
JSON

policy="$(jq -c . "$policy_file")"

radosgw-admin role create \
  --rgw-realm berries \
  --role-name k8s-workload-s3 \
  --assume-role-policy-doc "$policy"
