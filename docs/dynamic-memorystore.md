## Create dynamically a new Memorystore (Redis) instance

The goal is to define the connection to your Memorystore (Redis) instance from Humanitec for a dedicated `dev-gcp` Environment. We will provide below the basic requirements that your Memorystore (Redis) instance should meet.

You need to [define your GKE cluster in Humanitec](byo-gke.md) first.

We are defining this use case for the Staging Environment:
```bash
ENVIRONMENT=staging

humctl create environment-type ${ENVIRONMENT}
```

As Platform Engineer, in Google Cloud.

Create the GSA to provision the Terraform resources from Humanitec:
```bash
SA_NAME=humanitec-terraform
SA_ID=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${SA_NAME} \
    --display-name=${SA_NAME}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SA_ID}" \
    --role "roles/editor"
gcloud iam service-accounts keys create ${SA_NAME}.json \
    --iam-account ${SA_ID}
```

As Platform Engineer, in Humanitec, for Production Environment.

Create the associated resource definition in Humanitec:
```bash
cat <<EOF > memorystore-new.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: memorystore-new
object:
  name: memorystore-new
  type: redis
  driver_type: ${HUMANITEC_ORG}/terraform
  driver_inputs:
    values:
      append_logs_to_error: true
      source:
        path: resources/memorystore-new
        rev: refs/heads/main
        url: https://github.com/Humanitec-DemoOrg/google-cloud-reference-architecture.git
      variables:
        project_id: ${PROJECT_ID}
        region: ${REGION}
        network: ${NETWORK}
    secrets:
      variables:
        credentials: $(cat ${SA_NAME}.json | jq -r tostring)
  criteria:
    - env_id: ${ENVIRONMENT}
humctl create \
    -f memorystore-new.yaml
```

Now we need to apply all these resources definitions by deploying the Workloads in a new dedicated Environment.

Create the new dedicatd Environment by cloning the existing `development` Environment from its latest Deployment:
```bash
humctl create environment ${ENVIRONMENT} \
    --name ${ENVIRONMENT} \
    -t ${ENVIRONMENT} \
    --context ${HUMANITEC_CONTEXT}/apps/${ONLINEBOUTIQUE_APP} \
    --from development
```

Deploy this new Environment:
```bash
humctl deploy env development ${ENVIRONMENT} \
    --context ${HUMANITEC_CONTEXT}/apps/${ONLINEBOUTIQUE_APP}
```

Get the public DNS exposing the `frontend` Workload to test it:
```bash
humctl get active-resources \
	--context ${HUMANITEC_CONTEXT}/apps/${ONLINEBOUTIQUE_APP}/envs/${ENVIRONMENT} \
	-o json \
	| jq -c '.[] | select(.object.type | contains("dns"))' \
	| jq -r .object.resource.host
```