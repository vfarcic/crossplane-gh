import file

[
    {
        apiVersion = "apiextensions.crossplane.io/v1"
        kind = "Composition"
        metadata = {
            name = "github"
        }
        spec = {
            compositeTypeRef = {
                apiVersion = "devopstoolkitseries.com/v1alpha1"
                kind = "GitHub"
            }
            mode = "Pipeline"
            pipeline = [
                {
                    step = "github"
                    functionRef.name = "crossplane-contrib-function-kcl"
                    input = {
                        apiVersion = "krm.kcl.dev/v1alpha1"
                        kind = "KCLRun"
                        spec.source = file.read("kcl/github.k")
                    }
                }, {
                    step = "automatically-detect-ready-composed-resources"
                    functionRef.name = "crossplane-contrib-function-auto-ready"
                }
            ]
            writeConnectionSecretsToNamespace = "crossplane-system"
        }
    }
]