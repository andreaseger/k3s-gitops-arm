# Sealed Secrets

## Install kubeseal locally

```bash
# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.9.5/kubeseal-linux-amd64 -O kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm -rf kubeseal

# MacOS
brew install kubeseal
```

## Create sealed-secrets public certificate

```bash
cd secrets
kubeseal --controller-name sealed-secrets --fetch-cert > ./pub-cert.pem
```

## Fill in the secrets environment file

```bash
cd secrets
cp .env.secrets.sample .env.secrets
```

## Generate secrets

```bash
cd secrets
./generate-secrets.sh
```

## Backup & restore master key

Backup via

```
$ kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master.key
```

Restore via

```
$ kubectl apply -f master.key
$ kubectl delete pod -n kube-system -l name=sealed-secrets-controller
```