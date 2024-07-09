set -e

gum confirm '
This script will destroy everything done in the demo.
Are you ready to start?
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

rm -f apps/*.yaml

rm -f git-repos/*.yaml

git add .

git commit -m "Destroy"

git push

COUNTER=$(kubectl get managed --no-headers | grep -v object | wc -l)

while [ $COUNTER -ne 0 ]; do
    sleep 10
    echo "Waiting for $COUNTER resources to be deleted"
    COUNTER=$(kubectl get managed --no-headers | grep -v object | wc -l)
done

gh repo view $GITHUB_OWNER/crossplane-gh-demo --web

kind delete cluster

gum format '## Open "Settings", click the "Delete this repository" button, and follow the instructions.'
