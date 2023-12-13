## Bring your own GKE cluster

The goal is to define the connection to your GKE cluster from Humanitec for the Development Environment. We will provide below the basic requirements that your GKE cluster should meet.

As Platform Engineer, in Google Cloud.

```bash
ENVIRONMENT=development

PROJECT_ID=FIXME
gcloud config set project ${PROJECT_ID}
CLUSTER_NAME=gke-${ENVIRONMENT}
REGION=northamerica-northeast1
ZONE=${REGION}-a
NETWORK=default
```

Create the GKE cluster:
```bash
gcloud container clusters create ${CLUSTER_NAME} \
    --zone ${ZONE} \
    --network ${NETWORK} \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --scopes cloud-platform \
    --machine-type n2d-standard-4
```
_Note: this GKE cluster is not production ready, more security features need to be used. It's just an example to illustrate the integration with Humanitec._

```bash
gcloud container clusters get-credentials ${CLUSTER_NAME} \
    --zone ${ZONE}
```

Deploy the Nginx Ingress Controller:
```bash
helm upgrade \
    --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace
```

Grab the Public IP address of that Ingress Controller:
```bash
INGRESS_IP=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
echo ${INGRESS_IP}
```

Create a Google Service Account (GSA) with the appropriate role to access the GKE cluster from Humanitec:
```bash
GKE_ADMIN_SA_NAME=humanitec-to-${CLUSTER_NAME}
GKE_ADMIN_SA_ID=${GKE_ADMIN_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${GKE_ADMIN_SA_NAME} \
    --display-name=${GKE_ADMIN_SA_NAME}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${GKE_ADMIN_SA_ID}" \
    --role "roles/container.admin"
```

Download locally the GSA key:
```bash
gcloud iam service-accounts keys create ${GKE_ADMIN_SA_NAME}.json \
    --iam-account ${GKE_ADMIN_SA_ID}
```

As Platform Engineer, in Humanitec, for any Environments.

Create the GKE access resource definition for the dedicated Environment:
```bash
cat <<EOF > ${CLUSTER_NAME}.yaml
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: ${CLUSTER_NAME}
entity:
  name: ${CLUSTER_NAME}
  type: k8s-cluster
  driver_type: humanitec/k8s-cluster-gke
  driver_inputs:
    values:
      loadbalancer: ${INGRESS_IP}
      name: ${CLUSTER_NAME}
      project_id: ${PROJECT_ID}
      zone: ${ZONE}
    secrets:
      credentials: $(cat ${GKE_ADMIN_SA_NAME}.json)
  criteria:
    - {}
EOF
humctl create \
    -f ${CLUSTER_NAME}.yaml
```

Now we need to apply all these resources definitions by deploying the Workloads in a new dedicated Environment.

As Platform Engineer, in Humanitec.

Deploy this new Environment:
```bash
humctl deploy env development ${ENVIRONMENT} \
    --app ${ONLINEBOUTIQUE_APP}
```

Get the public DNS exposing the `frontend` Workload to test it:
```bash
humctl get active-resources \
	--app ${ONLINEBOUTIQUE_APP} \
    --env ${ENVIRONMENT} \
	-o json \
	| jq -c '.[] | select(.metadata.type | contains("dns"))' \
	| jq -r .status.resource.host
```