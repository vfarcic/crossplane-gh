import file

schema composition:
    _source: str
    apiVersion = "apiextensions.crossplane.io/v1"
    kind = "Composition"
    metadata = {
        name = "github"
    }
    spec = {
        compositeTypeRef = {
            apiVersion = "devopstoolkitseries.com/v1alpha1"
            kind = "CompositeCluster"
        }
        mode = "Pipeline"
        pipeline = [
            {
                step = "github"
                functionRef.name = "crossplane-contrib-function-kcl"
                input = {
                    apiVersion = "krm.kcl.dev/v1alpha1"
                    kind = "KCLRun"
                    spec.source = _source
                }
            }, {
                step = "automatically-detect-ready-composed-resources"
                functionRef.name = "crossplane-contrib-function-auto-ready"
            }
        ]
        writeConnectionSecretsToNamespace = "crossplane-system"
    }
        
[
    composition {
        _source = file.read("kcl/github.k")
    }
]