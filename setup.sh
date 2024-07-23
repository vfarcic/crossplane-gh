set -e

gum confirm '
This script will setup up everything required to run the demo.
Are you ready to start?
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

rm -f .env

export KUBECONFIG=$PWD/kubeconfig.yaml
echo "export KUBECONFIG=$KUBECONFIG" >> .env

if [ -z $CLUSTER_TYPE ]; then

    echo "## Do you want to create a KinD (local), EKS, GKE, or no cluster (choose none if you already have one)?" | gum format
    CLUSTER_TYPE=$(gum choose "kind" "eks" "gke" "aks" "none")

fi

echo "export CLUSTER_TYPE=$CLUSTER_TYPE" >> .env

if [[ "$CLUSTER_TYPE" == "kind" ]]; then

    kind create cluster

elif [[ "$CLUSTER_TYPE" == "eks" ]]; then

    AWS_ACCESS_KEY_ID=$(gum input \
        --placeholder "AWS Access Key ID" \
        --value "$AWS_ACCESS_KEY_ID")
    echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> .env
    
    AWS_SECRET_ACCESS_KEY=$(gum input \
        --placeholder "AWS Secret Access Key" \
        --value "$AWS_SECRET_ACCESS_KEY" --password)
    echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
        >> .env

    eksctl create cluster --config-file eksctl.yaml \
        --kubeconfig kubeconfig.yaml

elif [[ "$CLUSTER_TYPE" == "gke" ]]; then

    export USE_GKE_GCLOUD_AUTH_PLUGIN=True

    export PROJECT_ID=dot-$(date +%Y%m%d%H%M%S)
    echo "export PROJECT_ID=$PROJECT_ID" >> .env

    gcloud auth login

    gcloud projects create $PROJECT_ID

    echo "## Open https://console.cloud.google.com/marketplace/product/google/container.googleapis.com?project=$PROJECT_ID in a browser and enable the Kubernetes API." \
            | gum format

    gum input --placeholder "Press the enter key to continue."

    export KUBECONFIG=$PWD/kubeconfig.yaml
    echo "export KUBECONFIG=$KUBECONFIG" >> .env

    gcloud container clusters create dot --project $PROJECT_ID \
        --zone us-east1-b --machine-type e2-standard-2 \
        --num-nodes 2 --enable-network-policy \
        --no-enable-autoupgrade

    helm upgrade --install traefik traefik \
        --repo https://helm.traefik.io/traefik \
        --namespace traefik --create-namespace --wait

    export INGRESS_HOST=$(kubectl --namespace traefik \
        get service traefik \
        --output jsonpath="{.status.loadBalancer.ingress[0].ip}")

    echo "export INGRESS_HOST=$INGRESS_HOST" >> .env

    yq --inplace \
        ".server.ingress.enabled = true" \
        argocd-values.yaml

    yq --inplace \
        ".server.ingress.hostname = \"argocd.$INGRESS_HOST.nip.io\"" \
        argocd-values.yaml

elif [[ "$CLUSTER_TYPE" == "aks" ]]; then

    az login

    RESOURCE_GROUP=dot-$(date +%Y%m%d%H%M%S)
    echo "export RESOURCE_GROUP=$RESOURCE_GROUP" >> .env

    export LOCATION=eastus

    az group create --name $RESOURCE_GROUP --location $LOCATION

    az aks create --resource-group $RESOURCE_GROUP --name dot \
        --node-count 3 --node-vm-size Standard_B2ms \
        --enable-managed-identity --generate-ssh-keys --yes

    az aks get-credentials --resource-group $RESOURCE_GROUP \
        --name dot --file $KUBECONFIG

fi


helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl apply --filename config.yaml

kubectl apply --filename providers/kubernetes-incluster.yaml

kubectl apply --filename providers/helm-incluster.yaml

gum spin --spinner dot \
    --title "Waiting for Crossplane providers to be deployed..." \
    -- sleep 60

gum spin --spinner dot \
    --title "Waiting for Crossplane providers to be healthy..." \
    -- kubectl wait \
    --for=condition=healthy provider.pkg.crossplane.io --all \
    --timeout 5m

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

if [ -z $HYPERSCALER ]; then

    echo "## Which Hyperscaler do you want to use for PostgreSQL (select 'none' to continue without database)?" \
        | gum format
    HYPERSCALER=$(gum choose "aws" "google" "azure" "none")

fi

echo "export HYPERSCALER=$HYPERSCALER" >> .env

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

elif [[ "$HYPERSCALER" == "google" ]]; then

    PROJECT_ID_DB=dot-db-$(date +%Y%m%d%H%M%S)
    echo "export PROJECT_ID_DB=$PROJECT_ID_DB" >> .env

    gcloud projects create ${PROJECT_ID_DB}

    echo "## Open https://console.cloud.google.com/billing/enable?project=$PROJECT_ID_DB  in a browser and select billing." \
        | gum format

    gum input --placeholder "Press the enter key to continue."

    echo "## Open https://console.cloud.google.com/apis/library/sqladmin.googleapis.com?project=$PROJECT_ID_DB in a browser and *ENABLE* the API." \
        | gum format

    gum input --placeholder "Press the enter key to continue."

    export SA_NAME=devops-toolkit

    export SA="${SA_NAME}@${PROJECT_ID_DB}.iam.gserviceaccount.com"

    gcloud iam service-accounts create $SA_NAME --project $PROJECT_ID_DB

    export ROLE=roles/admin

    gcloud projects add-iam-policy-binding --role $ROLE $PROJECT_ID_DB \
        --member serviceAccount:$SA

    gcloud iam service-accounts keys create gcp-creds.json \
        --project $PROJECT_ID_DB --iam-account $SA

    kubectl --namespace crossplane-system create secret generic gcp-creds \
        --from-file creds=./gcp-creds.json

    yq --inplace ".spec.projectID = \"$PROJECT_ID_DB\"" \
        providers/provider-google-config.yaml

    kubectl apply --filename providers/provider-google-config.yaml

elif [[ "$HYPERSCALER" == "azure" ]]; then

    AZURE_TENANT_ID=$(gum input --placeholder "Azure Tenant ID" \
        --value "$AZURE_TENANT_ID")
    echo "export AZURE_TENANT_ID=$AZURE_TENANT_ID" >> .env

    az login --tenant $AZURE_TENANT_ID

    export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

    az ad sp create-for-rbac --sdk-auth --role Owner \
        --scopes /subscriptions/$SUBSCRIPTION_ID | tee azure-creds.json

    kubectl --namespace crossplane-system create secret generic azure-creds \
        --from-file creds=./azure-creds.json

    kubectl apply --filename providers/provider-azure-config.yaml

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
    examples/repo-$HYPERSCALER.yaml

yq --inplace \
    ".spec.parameters.gitops.user = \"$GITHUB_OWNER\"" \
    examples/repo-$HYPERSCALER.yaml

yq --inplace \
    ".metadata.annotations.\"github.com/project-slug\" = \"$GITHUB_OWNER/crossplane-gh\"" \
    backstage/catalog-info.yaml

yq --inplace ".metadata.name = \"dot-github-$GITHUB_OWNER\"" \
    backstage/catalog-info.yaml

yq --inplace ".spec.owner = \"$GITHUB_OWNER/crossplane-gh\"" \
    backstage/catalog-info.yaml

yq --inplace ".metadata.name = \"dot-github-template-$GITHUB_OWNER\"" \
    backstage/catalog-template.yaml

yq --inplace ".metadata.title = \"dot-github-template-$GITHUB_OWNER\"" \
    backstage/catalog-template.yaml

yq --inplace ".spec.owner = \"$GITHUB_OWNER/crossplane-gh\"" \
    backstage/catalog-template.yaml

yq --inplace \
    ".spec.parameters[0].properties.repo.properties.user.default = \"$GITHUB_OWNER\"" \
    backstage/catalog-template.yaml

yq --inplace \
    ".spec.parameters[0].properties.gitops.properties.user.default = \"$GITHUB_OWNER\"" \
    backstage/catalog-template.yaml

git add .

git commit -m "Initial commit"

git push
