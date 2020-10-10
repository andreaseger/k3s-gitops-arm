#!/usr/bin/env bash

# Modified with credit to: billimek@github

#
# Running this script is dependent on your Ansible inventory file
# Ensure you have the right IPs and hostnames in the right section
#

USER="ane"
K3S_VERSION="v1.19.2+k3s1"

REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_BRANCH=$(git symbolic-ref HEAD 2>/dev/null | sed -e 's|^refs/heads/||')
ANSIBLE_INVENTORY="${REPO_ROOT}/ansible/inventory"

die() { echo "$*" 1>&2 ; exit 1; }
need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "curl"
need "ssh"
need "kubectl"
need "helm"
need "k3sup"
need "ansible-inventory"
need "jq"
need "linkerd"

K3S_MASTER=$(ansible-inventory -i ${ANSIBLE_INVENTORY} --list | jq -r '.k3s_master[] | @tsv')
# K3S_WORKERS=$(ansible-inventory -i ${ANSIBLE_INVENTORY} --list | jq -r '.k3s_worker[] | @tsv')

message() {
  echo -e "\n######################################################################"
  echo "# ${1}"
  echo "######################################################################"
}

prepNodes() {
    message "Prepare Nodes via ansible"
    export ANSIBLE_CONFIG=ansible/ansible.cfg
    ansible-playbook \
        -i ansible/inventory \
        ansible/playbook.yml
    sleep 15
}

k3sMasterNode() {
    message "Installing k3s master to ${K3S_MASTER}"
    k3sup install --ip "${K3S_MASTER}" \
        --k3s-version "${K3S_VERSION}" \
        --user "${USER}" \
        --ssh-key ~/.ssh/id_ed25519 \
        --k3s-extra-args "--disable traefik --default-local-storage-path /k3s-local-storage"
        # --k3s-extra-args "--disable servicelb --disable traefik --disable metrics-server --default-local-storage-path /k3s-local-storage"
    mkdir -p ~/.kube
    mv ./kubeconfig ~/.kube/config
    sleep 10
}

ks3WorkerNodes() {
    for worker in $K3S_WORKERS; do
        message "Joining ${worker} to ${K3S_MASTER}"
        k3sup join --ip "${worker}" \
            --server-ip "${K3S_MASTER}" \
            --k3s-version "${K3S_VERSION}" \
            --user "${USER}" \
            --ssh-key ~/.ssh/id_ed25519
            ## Does not work :(
            #--k3s-extra-args "--node-label role.node.kubernetes.io/worker=worker"

        sleep 10

        message "Labeling ${worker} as node-role.kubernetes.io/worker=worker"
        hostname=$(ansible-inventory -i ${ANSIBLE_INVENTORY} --list | jq -r --arg k3s_worker "$worker" '._meta[] | .[$k3s_worker].hostname')
        kubectl label node ${hostname} node-role.kubernetes.io/worker=worker
    done
}

installSealedSecrets(){
    message "Installing sealed-secrets"

    kubectl apply -f "${REPO_ROOT}"/deployments/kube-system/sealed-secrets/sealed-secrets.yaml

    sleep 5

    SEALED_SECRETS_READY=1
    while [ ${SEALED_SECRETS_READY} != 0 ]; do
        echo "Waiting for sealed-secrets job to be done..."
        kubectl -n kube-system wait --for condition=complete job.batch/helm-install-sealed-secrets
        SEALED_SECRETS_READY="$?"
        sleep 5
    done
    SEALED_SECRETS_READY=1
    while [ ${SEALED_SECRETS_READY} != 0 ]; do
        echo "Waiting for sealed-secrets pod to be fully ready..."
        kubectl -n kube-system wait --for condition=available deployment/sealed-secrets
        SEALED_SECRETS_READY="$?"
        sleep 5
    done
        
    sleep 5

    pushd ${REPO_ROOT}/secrets
        message "updating sealedsecrets"
        kubeseal --controller-name sealed-secrets --fetch-cert > ./pub-cert.pem
        ./generate-secrets.sh
    popd
    git commit -v -a -m "Bootstrap: regenerate secrets"
    git push -u origin $REPO_BRANCH
}

installLinkerd() {
    message "Installing linkerd"
    linkerd install | kubectl apply -f -
    echo "waiting for linkerd to be up..."
    linkerd check
}

installFlux() {
    message "Installing flux"

    kubectl apply -f "${REPO_ROOT}"/deployments/flux/namespace.yaml

    helm repo add fluxcd https://charts.fluxcd.io
    helm repo update
    helm upgrade --install flux --values "${REPO_ROOT}"/deployments/flux/flux/flux-values.yaml --namespace flux fluxcd/flux
    helm upgrade --install helm-operator --values "${REPO_ROOT}"/deployments/flux/helm-operator/helm-operator-values.yaml --namespace flux fluxcd/helm-operator

    FLUX_READY=1
    while [ ${FLUX_READY} != 0 ]; do
        echo "Waiting for flux pod to be fully ready..."
        kubectl -n flux wait --for condition=available deployment/flux
        FLUX_READY="$?"
        sleep 5
    done
    sleep 5
}

addDeployKey() {
    # grab output the key
    FLUX_KEY=$(kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2)
    echo FLUX_KEY

    # message "Adding the key to github automatically"
    #"${REPO_ROOT}"/setup/add-repo-key.sh "${FLUX_KEY}"
}

prepNodes
k3sMasterNode
# ks3WorkerNodes
installSealedSecrets
installLinkerd
installFlux
addDeployKey

sleep 5
message "All done!"
kubectl get nodes -o=wide
