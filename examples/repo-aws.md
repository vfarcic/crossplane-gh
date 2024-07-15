## Setup

> Watch the [GitHub CLI (gh) - How to manage repositories more efficiently](https://youtu.be/BII6ZY2Rnlc) video if you are not familiar with GitHub CLI.

```sh
gh repo fork vfarcic/crossplane-gh --clone --remote

cd crossplane-gh

gh repo set-default
```

> Select the fork as the default repository

> Make sure that Docker is up-and-running. We'll use it to create a KinD cluster.

> Watch [Nix for Everyone: Unleash Devbox for Simplified Development](https://youtu.be/WiFLtcBvGMU) if you are not familiar with Devbox. Alternatively, you can skip Devbox and install all the tools listed in `devbox.json` yourself.

```sh
devbox shell
```

> The setup assumes that you are using AWS. Please open an issue if you would like me to add the support for Azure or Google Cloud. Alternatively, you can select `none` during the setup resulting in no database being created (but everything else working).

```sh
chmod +x setup.sh

./setup.sh
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

crossplane beta trace sqlclaim crossplane-gh-demo-db \
    --namespace a-team

kubectl get aws

cat package/compositions.yaml

cat kcl/github.k
```

## Destroy

```sh
rm apps/*.yaml

rm git-repos/*.yaml

git add .

git commit -m "Destroy"

git push

kubectl get managed
```

> Wait until all managed resources are removed (ignore `object`)

> Deleting repos is disabled in the Composition (by design), so it needs to be deleted manually.

```sh
gh repo view $GITHUB_OWNER/crossplane-gh-demo --web
```

> Open `Settings`, click the `Delete this repository`, and follow the instructions.

```sh
kind delete cluster
```