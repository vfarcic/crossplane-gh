apiVersion = "apiextensions.crossplane.io/v1"
kind = "CompositeResourceDefinition"
metadata = {
    name = "githubs.devopstoolkitseries.com"
    labels.idp = "true"
}
spec = {
    group = "devopstoolkitseries.com"
    names = {kind = "GitHub", plural = "githubs"}
    claimNames = {kind = "GitHubClaim", plural = "githubclaims"}
    versions = [{
        name = "v1alpha1"
        served = True
        referenceable = True
        $schema = {
            openAPIV3Schema = {
                type = "object"
                properties = {
                    # FIXME: Rewrite
                    spec = {}
                    # FIXME: Rewrite
                    status = {}
                }
            }
        }
    }]
}
