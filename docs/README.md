## Common Namespaces and Deployments

```mermaid
flowchart LR
  subgraph Humanitec
    subgraph Resources
      custom-namespace>custom-namespace]
      custom-workload>custom-workload]
    end
  end
```

- [Customize the `securityContext` of the Deployments](custom-workload.md)
- [Customize the name of the Namespace and add PSS label](custom-namespace.md)

## Google Cloud - GKE

```mermaid
flowchart LR
  subgraph Humanitec
    direction LR
    subgraph onlineboutique-app [Online Boutique App]
      subgraph dev-gcp
        direction LR
        cartservice-workload([cartservice])
        frontend-workload([frontend])
      end
    end
    subgraph Resources
        gke-connection>gke-connection]
        gke-logging-connection>gke-logging-connection]
        in-cluster-redis>in-cluster-redis]
    end
  end
  subgraph Google Cloud
    direction TB
    subgraph gke
        subgraph ingress-controller
            nginx{{nginx}}
        end
        subgraph onlineboutique
            frontend-->cartservice
            cartservice-->redis-cart
        end
        nginx-->frontend
    end
    gke-admin-gsa[\gke-admin-gsa/]
    gke-connection-.->gke-admin-gsa
    gke-logging-connection-.->gke-admin-gsa
    gke-admin-gsa-->gke
    in-cluster-redis-.->redis-cart
    onlineboutique-app-->onlineboutique
  end
  enduser((End user))-->nginx
```

- [Bring your own GKE cluster](byo-gke.md)
- [Bring your own Google Cloud Logging](byo-gcp-logging.md)