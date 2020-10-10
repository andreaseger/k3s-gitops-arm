# Things to install on the control server

## Ansible

```
sudo apt install ansible
```

## jq

```
sudo apt install jq
```

## k3sup

```
curl -sLS https://get.k3sup.dev | sh
mv k3sup ~/.local/bin/
```

## kubectl

```
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
```

## kubeseal

```
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.6/kubeseal-linux-amd64 -O ~/.local/bin/kubeseal
chmod +x ~/.local/bin/kubeseal
```

## helm

```
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```