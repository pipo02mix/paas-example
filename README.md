# Build your on PaaS 

The idea here is to help you through the path of creating a platform to create platforms with different configuration, tooling or addons on them.


## Requirements

- [clusterctl](https://cluster-api.sigs.k8s.io/user/quick-start.html)
- [clusterawsadm](https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases)
- [apptestctl](https://github.com/giantswarm/apptestctl)
- [helm](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

## Create a Management Cluster

In order to create platforms with our desired taste, we need to start creating a Management cluster (Kubernetes) which will serve a single API to manage everything.

In this example we will use [kind](https://kind.sigs.k8s.io/). It is the easiest way to provision a Kubernetes clusters these days, but feel free to use a managed solution or any other bootstrap tool.

Once the command line tool is installed just run

```kind create cluster --name mgmt --config kind.yaml```

and it will provision a two worker cluster with all components needed to run our Management Cluster.

### Bootstrap controllers

To demonstrate how to extend Kubernetes API for our purpose, we will install [CAPI controllers](https://www.giantswarm.io/blog/giant-swarms-epic-journey-to-cluster-api-giant-swarm) so we will be able to create managed clusters at will. At the same time we will install [App operator](https://github.com/giantswarm/app-operator) to let us install apps in those managed clusters. Finally we will use [AWS ACK controllers](https://aws.amazon.com/blogs/containers/aws-controllers-for-kubernetes-ack/) to managed AWS resources in Kubernetes style.

I have created a bootstrap script that guides you through all


## Create our first platform

### Create a cluster
```
clusterctl get kubeconfig my-cluster > /tmp/k.yaml
```

```
kubectl apply -f manifests/cluster.yaml
```

when cluster api is up 

```
k --kubeconfig=/tmp/k.yaml apply -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml
```



### Create an app


```
kubectl create secret generic my-cluster-config --from-file=value=/tmp/k.yaml
```

```
kubectl apply -f manifests/catalog.yaml
```

```
kubectl apply -f manifests/prometheus-app.yaml
```

### Create a S3 bucket


```
kubectl apply -f manifests/bucket.yaml
```
