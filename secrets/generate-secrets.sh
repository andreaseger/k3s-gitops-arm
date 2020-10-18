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

#
# Helm Secrets
#

./kseal "${REPO_ROOT}/deployments/default/radarr/radarr-helm-values.txt"
./kseal "${REPO_ROOT}/deployments/default/sonarr/sonarr-helm-values.txt"
./kseal "${REPO_ROOT}/deployments/default/nzbget/nzbget-helm-values.txt"
./kseal "${REPO_ROOT}/deployments/default/nzbhydra2/nzbhydra2-helm-values.txt"
./kseal "${REPO_ROOT}/deployments/default/home-assistant/home-assistant-helm-values.txt"
./kseal "${REPO_ROOT}/deployments/default/pihole/pihole-helm-values.txt"
./kseal "${REPO_ROOT}/deployments/default/plex/plex-helm-values.txt"

./kseal "${REPO_ROOT}/deployments/kube-system/traefik-ingress/traefik-config-helm-values.txt"

#
# Generic Secrets
#

# Traefik - kube-system Namespace
kubectl create secret generic traefik-secret \
  --from-literal=gandi-api-key="$GANDIV5_API_KEY" \
  --namespace kube-system --dry-run=client -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/kube-system/traefik-ingress/traefik-secret.yaml


# Traefik Basic Auth - default Namespace
kubectl create secret generic traefik-basic-auth \
  --from-literal=auth="$TRAEFIK_BASIC_AUTH" \
  --namespace default --dry-run=client -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/kube-system/traefik-ingress/basic-auth-default.yaml

# Traefik Basic Auth - kube-system Namespace
kubectl create secret generic traefik-basic-auth \
  --from-literal=auth="$TRAEFIK_BASIC_AUTH" \
  --namespace kube-system --dry-run=client -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/kube-system/traefik-ingress/basic-auth-kube-system.yaml

# Counter - default Namespace
kubectl create secret generic counter-secret \
  --from-literal=HASS_TOKEN="$HASS_TOKEN" \
  --namespace default --dry-run=client -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/default/stadthallenbad-counter/counter-secret.yaml

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