## Setup

```sh
devbox shell

kind create cluster

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait
```

FIXME: Switch to the configuration

```sh
kubectl apply --filename providers/function-auto-ready.yaml

kubectl apply --filename providers/function-kcl.yaml

kubectl apply --filename providers/provider-github.yaml

kubectl apply --filename package/definition.yaml && sleep 1

kubectl apply --filename package/compositions.yaml

sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all

kubectl wait --for=condition=healthy function.pkg.crossplane.io \
    --all

kubectl apply --filename providers/provider-github-config.yaml
```

> Replace `[...]` with your GitHub token

```sh
export GITHUB_TOKEN=[...]
```

> Replace `[...]` with your GitHub owner

```sh
export GITHUB_OWNER=[...]

echo "
apiVersion: v1
kind: Secret
metadata:
  name: github
  namespace: crossplane-system
type: Opaque
stringData:
  credentials: '{\"token\":\"${GITHUB_TOKEN}\",\"owner\":\"${GITHUB_OWNER}\"}'
" | kubectl --namespace crossplane-system apply --filename -

kubectl create namespace a-team
```

## Example

```sh
kubectl --namespace a-team apply --filename examples/repo.yaml

crossplane beta trace githubclaim crossplane-gh-demo \
    --namespace a-team

gh repo view $GITHUB_OWNER/crossplane-gh-demo --web
```

FIXME: Check the contents of the branch

FIXME: Merge the branch

FIXME: Add Argo CD app

FIXME: Confirm that it was deployed

FIXME: Add the DB in Google

FIXME: Add the DB in Azure

FIXME: Add the DB in AWS

FIXME: Publish the configuration

FIXME: Show the composition source code