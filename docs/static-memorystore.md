## Bring your own Memorystore (Redis) instance

Create the Memorystore (Redis) database with a password in same region and network as the GKE cluster:
```bash
gcloud services enable redis.googleapis.com

REDIS_NAME=redis-cart
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

Create the Memorystore (Redis) resource definition:
```bash
cat <<EOF > redis-memorystore-static.yaml
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: redis-memorystore-static
entity:
  name: redis-memorystore-static
  type: redis
  driver_type: humanitec/echo
  driver_inputs:
    values:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT}
    secrets:
      password: ${REDIS_AUTH}
      username: ""
  criteria:
    - app_id: ${HUMANITEC_APPLICATION}
EOF
humctl create \
    -f redis-memorystore-static.yaml
```

You can now redeploy your `cartservice` Workload to use this static Memorystore (Redis) database.