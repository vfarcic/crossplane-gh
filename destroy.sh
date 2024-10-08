set -e

gum confirm '
This script will destroy everything done in the demo.
Are you ready to start?
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

git pull

rm -f apps/*.yaml

rm -f git-repos/*.yaml

set +e

git add .

git commit -m "Destroy [skip ci]"

git push

set -e

gum spin --spinner line \
    --title "Waiting for Argo CD to pick up the changes (90 sec.)..." \
    -- sleep 90

kubectl --namespace a-team delete sqlclaim crossplane-gh-demo-db

kubectl --namespace a-team delete appclaim crossplane-gh-demo

COUNTER=$(kubectl get managed --no-headers | grep -v object | grep -v user \
    | wc -l | tr -d '[:space:]')

while [ $COUNTER -ne 0 ]; do
    sleep 10
    echo "Waiting for $COUNTER resources to be deleted"
    COUNTER=$(kubectl get managed --no-headers | grep -v object | grep -v user \
        | wc -l | tr -d '[:space:]')
done

if [[ "$CLUSTER_TYPE" == "kind" ]]; then
    
    kind delete cluster

elif [[ "$CLUSTER_TYPE" == "aks" ]]; then

    az group create --name $RESOURCE_GROUP --location eastus

elif [[ "$CLUSTER_TYPE" == "gke" ]]; then

    rm $KUBECONFIG

    gcloud container clusters delete dot --project ${PROJECT_ID} \
        --zone us-east1-b --quiet

    gcloud projects delete ${PROJECT_ID} --quiet

elif [[ "$CLUSTER_TYPE" == "eks" ]]; then

    eksctl delete cluster --config-file eksctl.yaml

fi

if [[ "$HYPERSCALER" == "google" ]]; then

    gcloud projects delete ${PROJECT_ID_DB} --quiet

fi

gh repo view $GITHUB_OWNER/crossplane-gh-demo --web

gum format '## Open "Settings", click the "Delete this repository" button, and follow the instructions.'

gum input --placeholder "Press the enter key to continue."

gh repo view $GITHUB_OWNER/crossplane-gh --web

gum format '## Open "Settings", click the "Delete this repository" button, and follow the instructions.'
