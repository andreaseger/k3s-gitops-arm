# WIP k3s homelab

![Kubernetes](https://i.imgur.com/p1RzXjQ.png)

Build a [Kubernetes](https://kubernetes.io/) ([k3s](https://github.com/rancher/k3s)) cluster with RPis and utilize [GitOps](https://www.weave.works/technologies/gitops/) for managing cluster state. Based on [k3s-gitops-arm](https://github.com/onedr0p/k3s-gitops-arm) by [@onedr0p](https://github.com/onedr0p).

This repo uses a lot of multi-arch images provided by [raspbernetes/multi-arch-images](https://github.com/raspbernetes/multi-arch-images).

> **Note**: A lot of files in this project have **@CHANGEME** comments, these are things that are specific to my set up that you may need to change.

* * *

## Prerequisites

### Hardware - so far

(Mostly things I already had around except the rpi4, will be extended in the future)

- 1x Raspberry Pi 4 8GB
- 1x 128GB SD-card (mostly unused except OS)
- 1x USB flashdrive for local storage
- 256GB SSD via USB 3 adapter (likely as base for longhorn)

### Software

> **Note**: I use the fish shell for a lot of my commands. Some will work in Bash but others will not, see [here](docs/fish-shell.md) for more information.

- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [hypriot/flash](https://github.com/hypriot/flash)
- [alexellis/k3sup](https://github.com/alexellis/k3sup)
- helm
- kubeseal

* * *

## Directory topology

```bash
.
├── ./ansible        # Ansible playbook to run after the RPis have been flashed
├── ./deployments    # Flux will only scan and deploy from this directory
├── ./setup          # Setup of the cluster
├── ./secrets        # Scripts to generate secrets for Sealed Secrets
└── ./docs           # Documentation
```

* * *

## Let's get started

### 1. Flash SD Card with Ubuntu

> See [ubuntu.md](docs/ubuntu.md)

### 2. Provision RPis with Ansible

[Ansible](https://www.ansible.com) is a great automation tool and here I am using it to provision the RPis.

> See [ansible.md](docs/ansible.md) and review the files in the [ansible](ansible) folder.

### 3. Install k3s on your RPis using k3sup

[k3sup](https://k3sup.dev) is a neat tool provided by [@alexellis](https://github.com/alexellis) that helps get your k3s cluster up and running quick.

> For manual deployment see [k3sup.md](docs/k3sup.md), and for an automated script see [bootstrap-cluster.sh](setup/bootstrap-cluster.sh)

### 4. Flux and Helm Operator

[Helm](https://v3.helm.sh/) is a package manager for Kubernetes.

[Flux](https://docs.fluxcd.io/en/stable/) is the [GitOps](https://www.weave.works/technologies/gitops/) tool I've chosen to have this Git Repository manage my clusters state.

> For manual deployment see [helm-flux.md](docs/flux-helm-operator.md), and for an automated script see [bootstrap-cluster.sh](setup/bootstrap-cluster.sh)

## Additional Components

### Sealed Secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) are a "one-way" encrypted Secret that can be created by anyone, but can only be decrypted by the controller running in the target cluster. The Sealed Secret is safe to share publicly, upload to git repositories, give to the NSA, etc. Once the Sealed Secret is safely uploaded to the target Kubernetes cluster, the sealed secrets controller will decrypt it and recover the original Secret.

> See [sealed-secrets.md](docs/sealed-secrets.md) and review the files in the [secrets](secrets) folder.
