#!/usr/bin/env bash

set -euo pipefail

trust_policy_file="$(mktemp)"
permission_policy_file="$(mktemp)"
trap 'rm -f "$trust_policy_file" "$permission_policy_file"' EXIT

cat >"$trust_policy_file" <<'JSON'
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
        "StringLike": {
          "k8s.noa.re:sub": "system:serviceaccount:reposnake:default"
        }
      }
    }
  ]
}
JSON

cat >"$permission_policy_file" <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:ListBucket",
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::repo-noa-re"
    },
    {
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::repo-noa-re/*"
    }
  ]
}
JSON

trust_policy="$(jq -c . "$trust_policy_file")"
permission_policy="$(jq -c . "$permission_policy_file")"

radosgw-admin role create \
  --rgw-realm berries \
  --role-name reposnake \
  --assume-role-policy-doc "$trust_policy"

radosgw-admin role-policy put \
  --rgw-realm berries \
  --role-name reposnake \
  --policy-name repo-noa-re-access \
  --policy-doc "$permission_policy"
