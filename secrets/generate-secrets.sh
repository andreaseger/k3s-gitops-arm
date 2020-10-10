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

if [ "$(uname)" == "Darwin" ]; then
  set -a
  . "${REPO_ROOT}/secrets/.secrets.env"
  set +a
else
  . "${REPO_ROOT}/secrets/.secrets.env"
fi

PUB_CERT="${REPO_ROOT}/secrets/pub-cert.pem"

# Helper function to generate secrets
kseal() {
  echo "------------------------------------"
  # Get the path and basename of the txt file
  # e.g. "deployments/default/pihole/pihole-helm-values"
  secret="$(dirname "$@")/$(basename -s .txt "$@")"
  echo "Secret: ${secret}"
  # Get the filename without extension
  # e.g. "pihole-helm-values"
  secret_name=$(basename "${secret}")
  echo "Secret Name: ${secret_name}"
  # Extract the Kubernetes namespace from the secret path
  # e.g. default
  namespace="$(echo "${secret}" | awk -F /deployments/ '{ print $2; }' | awk -F / '{ print $1; }')"
  echo "Namespace: ${namespace}"
  # Create secret and put it in the applications deployment folder
  # e.g. "deployments/default/pihole/pihole-helm-values.yaml"
  envsubst < "$@" | tee values.yaml \
    | \
  kubectl -n "${namespace}" create secret generic "${secret_name}" \
    --from-file=values.yaml --dry-run=client -o json \
    | \
  kubeseal --format=yaml --cert="$PUB_CERT" \
    > "${secret}.yaml"
  # Clean up temp file
  rm values.yaml
}

#
# Helm Secrets
#

kseal "${REPO_ROOT}/deployments/default/radarr/radarr-helm-values.txt"
kseal "${REPO_ROOT}/deployments/default/sonarr/sonarr-helm-values.txt"
kseal "${REPO_ROOT}/deployments/default/nzbget/nzbget-helm-values.txt"
kseal "${REPO_ROOT}/deployments/default/nzbhydra2/nzbhydra2-helm-values.txt"
kseal "${REPO_ROOT}/deployments/default/home-assistant/home-assistant-db-helm-values.txt"
kseal "${REPO_ROOT}/deployments/default/home-assistant/home-assistant-helm-values.txt"

#
# Generic Secrets
#

# Traefik - default Namespace
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

# Traefik Basic Auth - linkerd Namespace
kubectl create secret generic traefik-basic-auth \
  --from-literal=auth="$TRAEFIK_BASIC_AUTH" \
  --namespace kube-system --dry-run=client -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/linkerd/basic-auth-linkerd.yaml
