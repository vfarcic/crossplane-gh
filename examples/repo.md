## Setup

FIXME: tmp.yaml

FIXME: Fork the repo

FIXME: Convert to a script

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

kubectl apply --filename providers/kubernetes-incluster.yaml

kubectl apply --filename providers/configuration-dot-app.yaml

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

kubectl create namespace git-repos

REPO_URL=$(git config --get remote.origin.url)

helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --values argocd-values.yaml --wait

yq --inplace \
    ".spec.source.repoURL = \"https://github.com/$GITHUB_OWNER/crossplane-gh\"" \
    argocd-apps.yaml

kubectl apply --filename argocd-apps.yaml

yq --inplace \
    ".spec.parameters.repo.user = \"$GITHUB_OWNER\"" \
    examples/repo.yaml

yq --inplace \
    ".spec.parameters.gitops.user = \"$GITHUB_OWNER\"" \
    examples/repo.yaml
```

## Example

```sh
cp examples/repo.yaml git-repos/crossplane-gh-demo.yaml

git add .

git commit -m "Repo"

git push

crossplane beta trace githubclaim crossplane-gh-demo \
    --namespace git-repos
```

> If the output throws an `error`, Argo CD probably did not yet synchronize it. Wait for a few moments and try again.

> Wait until the `STATUS` of all the resources is `Available`

```sh
gh repo view $GITHUB_OWNER/crossplane-gh-demo --web
```

> Observe the `init` branch and files in it.

> Observe the `Initial` pull request.

> Follow the instructions in the pull request description.

> Merge the pull request.

> Observe GitHub Actions workflow run.

```sh
crossplane beta trace appclaim crossplane-gh-demo \
    --namespace a-team
```

> If the output throws an `error`, Argo CD probably did not yet synchronize it. Wait for a few moments and try again.

```sh
kubectl --namespace a-team get all,ingresses
```

FIXME: Add the DB in Google

FIXME: Add the DB in Azure

FIXME: Add the DB in AWS

FIXME: Add devbox.json

FIXME: Publish the configuration

FIXME: Show the composition source code

FIXME: Upbound spaces

FIXME: What else should I add?

## Destroy

```sh
rm apps/*.yaml

rm git-repos/*.yaml

git add .

git commit -m "Destroy"

git push
```

> Deleting repos is disabled in the Composition (by design), so it needs to be deleted manually.

```sh
gh repo view $GITHUB_OWNER/crossplane-gh-demo --web
```

> Open `Settings`, click the `Delete this repository`, and follow the instructions.

```sh
kind delete cluster
```