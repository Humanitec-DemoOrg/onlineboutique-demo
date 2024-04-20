## Create dynamically a new Memorystore (Redis) instance

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

Create the associated resource definition in Humanitec:
```bash
cat <<EOF > redis-memorystore-dynamic.yaml
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: redis-memorystore-dynamic
entity:
  name: redis-memorystore-dynamic
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
    - app_id: ${HUMANITEC_APPLICATION}
      env_id: ${HUMANITEC_ENVIRONMENT}
humctl create \
    -f redis-memorystore-dynamic.yaml
```

You can now redeploy your `cartservice` Workload to use this dynamic Memorystore (Redis) database.