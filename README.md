<p align="center">
<img src="https://github.com/GoogleCloudPlatform/microservices-demo/raw/main/src/frontend/static/icons/Hipster_HeroLogoMaroon.svg" width="300" alt="Online Boutique" />
</p>

[![ci](https://github.com/Humanitec-DemoOrg/onlineboutique-demo/actions/workflows/ci.yaml/badge.svg)](https://github.com/Humanitec-DemoOrg/onlineboutique-demo/actions/workflows/ci.yaml)

Repository containing all the resources to deploy the [Online Boutique sample apps](https://github.com/GoogleCloudPlatform/microservices-demo) with Score and Humanitec.

Deploying the Online Boutique sample apps in Humanitec consists in 4 main steps:
- [Create the Online Boutique App](#create-the-online-boutique-app)
- [Configure an in-cluster Redis database](#configure-an-in-cluster-redis-database)
- [Deploy the Online Boutique Workloads](#deploy-the-online-boutique-workloads)
- [Enjoy!](#test-the-online-boutique-website)

As next steps, [there is more if you want](docs/README.md)! ;)

```mermaid
flowchart LR
  subgraph Humanitec
    direction LR
    subgraph onlineboutique-app [Online Boutique App]
        subgraph Development
          direction LR
          cartservice-workload([cartservice])
          frontend-workload([frontend])
        end
    end
    subgraph Resources
        in-cluster-redis>in-cluster-redis]
    end
  end
  subgraph cloud [Humanitec's Cloud]
      direction LR
      subgraph onlineboutique
          frontend{{frontend}}-->cartservice{{cartservice}}
          cartservice-->redis-cart
      end
  end
  onlineboutique-app-.->onlineboutique
  in-cluster-redis-.->redis-cart
  enduser((End user))-->frontend
```

```bash
export HUMANITEC_TOKEN=FIXME
export HUMANITEC_ORG=FIXME
export HUMANITEC_CONTEXT=/orgs/${HUMANITEC_ORG}
```

## Create the Online Boutique App

As Platform Admin, in Humanitec.

```bash
ONLINEBOUTIQUE_APP=onlineboutique
humctl create app ${ONLINEBOUTIQUE_APP} \
    --name ${ONLINEBOUTIQUE_APP}
```

```bash
ENVIRONMENT=development
```

## Configure an in-cluster Redis database

As Platform Admin, in Humanitec.

```bash
humctl create \
    -f resources/in-cluster-redis.yaml
```

## Deploy the Online Boutique Workloads

As Developer, in Humanitec.

### All in once

```bash
humctl score deploy \
	--app ${ONLINEBOUTIQUE_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	--deploy-config apps/score.deploy.yaml \
    --wait
```

### One by one

```bash
WORKLOAD=adservice #cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice
humctl score deploy \
	--app ${ONLINEBOUTIQUE_APP} \
	--env ${ENVIRONMENT} \
	--org ${HUMANITEC_ORG} \
	--token ${HUMANITEC_TOKEN} \
	-f apps/${WORKLOAD}/score.yaml \
	--extensions apps/${WORKLOAD}/humanitec.score.yaml \
    --wait
```

## Test the Online Boutique website

Get the public DNS exposing the `frontend` Workload:
```bash
humctl get active-resources \
    --app ${ONLINEBOUTIQUE_APP} \
    --env ${ENVIRONMENT} \
    -o json \
    | jq -c '.[] | select(.metadata.type | contains("dns"))' \
    | jq -r .status.resource.host
```
