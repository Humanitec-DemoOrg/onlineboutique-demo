## Bring your own Google Cloud Logging

The goal is to define the connection to the Google Cloud Logging of your GKE cluster from Humanitec. Instead of using the default `fluentbit` `Daemonset` deployed in any Namespace.

You need to [define your GKE cluster in Humanitec](byo-gke.md) first.

As Platform Engineer, in Google Cloud.

Assign the Google Service Account (GSA) to access the GKE cluster with the appropriate role to access Cloud Logging:
```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${GKE_ADMIN_SA_ID}" \
    --role "roles/logging.viewer"
```

As Platform Engineer, in Humanitec, for any Environments.

Create the Cloud Logging access resource definition for the dedicated Environment:
```bash
cat <<EOF > ${CLUSTER_NAME}-logging.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${CLUSTER_NAME}-logging
object:
  name: ${CLUSTER_NAME}-logging
  type: logging
  driver_type: humanitec/logging-gcp
  driver_inputs:
    values:
      cluster_name: \${resources.k8s-cluster#k8s-cluster.outputs.name}
      cluster_zone: \${resources.k8s-cluster#k8s-cluster.outputs.zone}
      project_id: \${resources.k8s-cluster#k8s-cluster.outputs.project_id}
    secrets:
      credentials: \${resources.k8s-cluster#k8s-cluster.outputs.credentials}
  criteria:
    - {}
EOF
humctl create \
    -f ${CLUSTER_NAME}-logging.yaml
```

Now we need to apply all this resource definition by deploying the Workloads in the dedicated Environment.