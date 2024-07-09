set -e

gum confirm '
This script will setup up everything required to run the demo.
Are you ready to start?
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

kind create cluster

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl apply --filename config.yaml

kubectl apply --filename providers/kubernetes-incluster.yaml

kubectl apply --filename providers/helm-incluster.yaml

gum spin --spinner dot \
    --title "Waiting for Crossplane providers to be deployed..." \
    -- sleep 30 && kubectl wait \
    --for=condition=healthy provider.pkg.crossplane.io --all

GITHUB_TOKEN=$(gum input --placeholder "GitHub Token" \
    --value "$GITHUB_TOKEN")
echo "export GITHUB_TOKEN=$GITHUB_TOKEN" >> .env

GITHUB_OWNER=$(gum input --placeholder "GitHub user or owner" \
    --value "$GITHUB_OWNER")
echo "export GITHUB_OWNER=$GITHUB_OWNER" >> .env

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

kubectl apply --filename providers/provider-github-config.yaml

echo "## Which Hyperscaler do you want to use?" | gum format
HYPERSCALER=$(gum choose "aws" "none")

if [[ "$HYPERSCALER" == "aws" ]]; then

    AWS_ACCESS_KEY_ID=$(gum input --placeholder "AWS Access Key ID" \
        --value "$AWS_ACCESS_KEY_ID")
    echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env

    AWS_SECRET_ACCESS_KEY=$(gum input \
        --placeholder "AWS Secret Access Key" \
        --value "$AWS_SECRET_ACCESS_KEY")
    echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> .env

    echo "[default]
    aws_access_key_id = $AWS_ACCESS_KEY_ID
    aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
    " >aws-creds.conf

    kubectl --namespace crossplane-system \
        create secret generic aws-creds \
        --from-file creds=./aws-creds.conf

    kubectl apply --filename providers/provider-aws-config.yaml

else

    yq --inplace ".spec.parameters.db.enabled = false" \
        examples/repo.yaml
    
fi

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
