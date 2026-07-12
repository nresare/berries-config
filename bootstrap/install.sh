#!/bin/bash
set -eux -o pipefail

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

TMPFILE=$(mktemp)

kubectl create namespace argo --dry-run=client -o yaml > $TMPFILE

echo "---" >> $TMPFILE

helm template argocd -n argo argo/argo-cd --version 10.1.3 \
  --include-crds --values minimal-argocd-values.yaml >> $TMPFILE

kubectl apply --server-side --field-manager=argocd-controller -f $TMPFILE
