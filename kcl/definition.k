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
                    spec = {
                        type = "object"
                        properties = {
                            id = {
                                type = "string"
                                description = "The unique ID (name) of the GitHub repository."
                            }
                            parameters = {
                                type = "object"
                                properties = {
                                    public = {
                                        type = "boolean"
                                        description = "Whether to make the repo public."
                                        default = False
                                    }
                                    app = {
                                        type = "object"
                                        properties = {
                                            language = {
                                                type = "string"
                                                description = "The language. Currently supported languages: go, js."
                                                default = "go"
                                            }
                                            host = {
                                                type = "string"
                                                description = "The host."
                                            }
                                            namespace = {
                                                type = "string"
                                                description = "The Namespace."
                                            }
                                        }
                                        required = ["host", "namespace"]
                                    }
                                }
                            }
                        }
                    }
                    # FIXME: Rewrite
                    status = {}
                }
            }
        }
    }]
}
