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

COUNTER=$(kubectl get managed --no-headers | grep -v object | wc -l | tr -d '[:space:]')

while [ $COUNTER -ne 0 ]; do
    sleep 10
    echo "Waiting for $COUNTER resources to be deleted"
    COUNTER=$(kubectl get managed --no-headers | grep -v object | wc -l | tr -d '[:space:]')
done

if [[ "$CLUSTER_TYPE" == "kind" ]]; then
    
    kind delete cluster

elif [[ "$CLUSTER_TYPE" == "gke" ]]; then

    rm $KUBECONFIG

    gcloud container clusters delete dot --project $PROJECT_ID \
        --zone us-east1-b --quiet

    gcloud projects delete $PROJECT_ID --quiet

fi

gh repo view $GITHUB_OWNER/crossplane-gh-demo --web

gum format '## Open "Settings", click the "Delete this repository" button, and follow the instructions.'