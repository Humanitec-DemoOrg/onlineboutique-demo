## Create a custom Namespace resource definition

As Platform Engineer, in Humanitec, for any Environments.

Customize the name of the Kubernetes Namespace for all your Apps in any Environment. One per App/Env. We are also adding the label to enforce Pod Security Standards `restricted`:

```bash
humctl create \
    -f resources/custom-namespace.yaml
```