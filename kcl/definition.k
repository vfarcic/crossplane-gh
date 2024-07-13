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
                                    registry = {
                                        type = "string"
                                        description = "Container image registry."
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
                                    db = {
                                        type = "object"
                                        properties = {
                                            enabled = {
                                                type = "boolean"
                                                description = "Whether to have a database server."
                                                default = False
                                            }
                                            provider = {
                                                type = "string"
                                                description = "The database provider. Currently supported providers: aws, azure, google."
                                                default = "aws"
                                            }
                                            version = {
                                                type = "string"
                                                description = "The database server version."
                                            }
                                        }
                                    }
                                    repo = {
                                        type = "object"
                                        properties = {
                                            user = {
                                                type = "string"
                                                description = "GitHub user where the repo with  GitOps (Argo CD) files is located."
                                            }
                                        }
                                        required = ["user"]
                                    }
                                    gitops = {
                                        type = "object"
                                        properties = {
                                            enabled = {
                                                type = "boolean"
                                                description = "Whether to enable GitOps."
                                                default = False
                                            }
                                            user = {
                                                type = "string"
                                                description = "GitHub user where the repo with  GitOps (Argo CD) files is located. This is a mandatory field if `enabled` is set to `true`."
                                            }
                                            repo = {
                                                type = "string"
                                                description = "GitHub repo with  GitOps (Argo CD) files is located. This is a mandatory field if `enabled` is set to `true`."
                                            }
                                        }
                                    }
                                    backstage = {
                                        type = "object"
                                        properties = {
                                            enabled = {
                                                type = "boolean"
                                                description = "Whether to enable Backstage."
                                                default = False
                                            }
                                        }
                                    }
                                    tools = {
                                        type = "object"
                                        properties = {
                                            tmux = {
                                                type = "boolean"
                                                default = False
                                                description = "Whether to enable tmux through Devbox."
                                            }
                                            registry = {
                                                type = "object"
                                                properties = {
                                                    enabled = {
                                                        type = "boolean"
                                                        description = "Whether to enable the container image registry."
                                                        default = False
                                                    }
                                                    namespace = {
                                                        type = "string"
                                                        description = "The Namespace."
                                                    }
                                                }
                                                required = ["namespace"]
                                            }
                                        }
                                    
                                    }
                                }
                                required = ["registry"]
                            }
                        }
                    }
                    status = {}
                }
            }
        }
    }]
}
