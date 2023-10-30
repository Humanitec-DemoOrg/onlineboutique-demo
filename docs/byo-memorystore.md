## Bring your own Memorystore (Redis) instance

The goal is to define the connection to your Memorystore (Redis) instance from Humanitec for a dedicated `dev-gcp` Environment. We will provide below the basic requirements that your Memorystore (Redis) instance should meet.

You need to [define your GKE cluster in Humanitec](byo-gke.md) first.

We are defining this use case for the Production Environment:
```bash
ENVIRONMENT=production

humctl create environment-type ${ENVIRONMENT}
```

As Platform Engineer, in Google Cloud.

Create the Memorystore (Redis) database with a password in same region and network as the GKE cluster:
```bash
gcloud services enable redis.googleapis.com

REDIS_NAME=redis-cart-${ENVIRONMENT}
gcloud redis instances create ${REDIS_NAME} \
    --size 1 \
    --region ${REGION} \
    --zone ${ZONE} \
    --network ${NETWORK} \
    --redis-version redis_7_0 \
    --enable-auth
```

```bash
REDIS_HOST=$(gcloud redis instances describe ${REDIS_NAME} \
    --region ${REGION} \
    --format 'get(host)')
echo ${REDIS_HOST}
REDIS_PORT=$(gcloud redis instances describe ${REDIS_NAME} \
    --region ${REGION} \
    --format 'get(port)')
echo ${REDIS_PORT}
REDIS_AUTH=$(gcloud redis instances get-auth-string ${REDIS_NAME} \
    --region ${REGION} \
    --format 'get(authString)')
echo ${REDIS_AUTH}
```

As Platform Engineer, in Humanitec, for Production Environment.

Create the Memorystore (Redis) instance access resource definition for the dedicated Environment:
```bash
cat <<EOF > ${REDIS_NAME}.yaml
apiVersion: core.api.humanitec.io/v1
kind: Definition
metadata:
  id: ${REDIS_NAME}
object:
  name: ${REDIS_NAME}
  type: redis
  driver_type: humanitec/static
  driver_inputs:
    values:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT}
    secrets:
      password: ${REDIS_AUTH}
      username: ""
  criteria:
    - env_type: ${ENVIRONMENT}
EOF
humctl create \
    -f ${REDIS_NAME}.yaml
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
