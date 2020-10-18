#!/usr/bin/env bash
set -e

export REPO_ROOT=$(git rev-parse --show-toplevel)

die() { echo "$*" 1>&2 ; exit 1; }

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubeseal"
need "kubectl"
need "sed"
need "envsubst"

set -o allexport
source "${REPO_ROOT}/secrets/.secrets.env"
set +o allexport

PUB_CERT="${REPO_ROOT}/secrets/pub-cert.pem"


# github container registry pull secret
kubectl -n default create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_CR_PAT \
  --docker-email=$GITHUB_EMAIL \
  --dry-run=client -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/default/gh-pull-secret.yaml