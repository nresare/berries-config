# Rook Ceph IAM bootstrap

These manual scripts bootstrap the IAM role used by Kubernetes workloads to
access the `berries` Ceph Object Gateway (S3-compatible storage). Run them in
numeric order.

Scripts 01, 02, 04, 06, and 07 use `radosgw-admin` and must run inside the
`rook-ceph-tools` container:

```sh
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
```

Scripts 03, 05, and 08 use the AWS CLI and must run locally against the RGW
endpoint forwarded to `http://localhost:8080`.

## 01: Create the IAM administrator

Run `01-create-iam-admin-user.sh` in the tools container. It creates the
`iam-admin` user and prints a generated access key and secret.

## 02: Grant IAM capabilities

Run `02-add-iam-admin-capabilities.sh` in the tools container. It grants the
administrator permissions to manage roles, OIDC providers, and user policies.

## 03: Create the OIDC provider

Configure a local AWS profile using the access key and secret printed by step
01:

```sh
aws configure --profile rgw-admin
```

Make the locally forwarded RGW endpoint available, then run
`03-create-oidc-provider.sh`:

```sh
export RGW_ENDPOINT=http://localhost:8080
./bootstrap/03-create-oidc-provider.sh
```

The script derives the lowercase SHA-1 fingerprint of the Let's Encrypt ISRG
Root X1 certificate, then creates the `https://k8s.noa.re` provider with
`sts.amazonaws.com` as its client ID.

## 04: Create the workload role

Run `04-create-workload-role.sh` in the tools container. It creates the
`k8s-workload-s3` role.

The trust policy allows only this Kubernetes service account to assume it:

```text
system:serviceaccount:default:default
```

Edit the script before running it if a different service account should be
trusted.

## 05: Verify workload identity

With `RGW_ENDPOINT` still set, run this locally:

```sh
./bootstrap/05-verify-workload-identity.sh
```

The script requests a Kubernetes token for the `default` service account in
the `default` namespace, then exchanges it for temporary credentials using the
`k8s-workload-s3` role.

## 06: Create the reposnake role

Run `06-create-reposnake-role.sh` in the tools container. It creates a
`reposnake` role trusted by the `default` service account in the `reposnake`
namespace.

The attached inline policy allows the role to list the `repo-noa-re` bucket and
to put, get, and delete objects within it.

## 07: Create the mimir role

Run `07-create-mimir-role.sh` in the tools container. It creates a `mimir` role
trusted by the `default` service account in the `mimir-test` namespace.

The attached inline policy allows the role to list the `mimir-data` bucket and
to put, get, and delete objects within it.

## 08: Create the repo-noa-re bucket

With `RGW_ENDPOINT` still set, run this locally:

```sh
./bootstrap/08-create-repo-noa-re-bucket.sh
```

The script uses the `rgw-admin` AWS profile to create the `repo-noa-re` bucket
through the S3 API.

These scripts are intended for initial bootstrap. Existing users, providers,
roles, or buckets may cause the corresponding command to fail. The role trust
policy only controls who may assume the role; S3 permissions must also be
attached to the role before workloads can access buckets.


## Also, argo-cd bootstrap

`install.sh`, referencing `minimal-argocd-values.yaml` will install argo-cd
with a minimal configuration, so that it can move to maintaining itself from
the berries-manifests repo