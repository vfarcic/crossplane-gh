set -e

gum confirm '
This script will destroy everything done in the demo.
Are you ready to start?
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

git pull

rm -f apps/*.yaml

rm -f git-repos/*.yaml

git add .

git commit -m "Destroy"

git push

COUNTER=$(kubectl get managed --no-headers | grep -v object | wc -l | tr -d '[:space:]')

while [ $COUNTER -ne 0 ]; do
    sleep 10
    echo "Waiting for $COUNTER resources to be deleted"
    COUNTER=$(kubectl get managed --no-headers | grep -v object | wc -l | tr -d '[:space:]')
done

kind delete cluster

gh repo view $GITHUB_OWNER/crossplane-gh-demo --web

if [[ "$CLUSTER_TYPE" == "gke" ]]; then

    rm $KUBECONFIG

    gcloud container clusters delete dot --project $PROJECT_ID \
        --zone us-east1-b --quiet

    gcloud projects delete $PROJECT_ID --quiet

fi


gum format '## Open "Settings", click the "Delete this repository" button, and follow the instructions.'