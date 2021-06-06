# Build your on PaaS 

The idea here is to help you through the path of creating a platform to create platforms with different configuration, tooling or addons on them.


## Requirements

- [AWS Account with a user and access key](https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key/)
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

__Note__: To get the kubeconfig of the Management cluster you can run
```
kind get kubeconfig --name="mgmt" 
```

### Bootstrap controllers

To demonstrate how to extend Kubernetes API for our purpose, we will install [CAPI controllers](https://www.giantswarm.io/blog/giant-swarms-epic-journey-to-cluster-api-giant-swarm) so we will be able to create managed clusters at will. At the same time we will install [App operator](https://github.com/giantswarm/app-operator) to let us install apps in those managed clusters. Finally we will use [AWS ACK controllers](https://aws.amazon.com/blogs/containers/aws-controllers-for-kubernetes-ack/) to managed AWS resources in Kubernetes style.

I have created a bootstrap script that guides you through all. In this guide we are using AWS as cloud provider to create our platform so you will need to initialize these variables

```
export AWS_REGION="eu-west-2" 
export AWS_ACCESS_KEY_ID="my-key-id"
export AWS_SECRET_ACCESS_KEY="my-secre-access-key"
export AWS_SSH_KEY_NAME="a-ssh-key-create-in-the-region-pointed-before"
-------- OPTIONAL -----------
export AWS_SESSION_TOKEN="" #in case you use MFA
export AWS_CONTROL_PLANE_MACHINE_TYPE="instance-type-you-want"
export AWS_NODE_MACHINE_TYPE="instance-type-you-want"
```

Now you are ready to execute the bootstrap script
```
 ./bootstrap-mgmt.sh
```

It guides you through the creation process, you can see the steps documented inside the script file.

## Create our first platform

Once the management cluster is ready and all controllers are running, it is time to start creating our first platform.

### Create a cluster

For that we will define a new Kubernetes cluster using the CAPI command line tool. The manifest is already created in the folder so this step is optional. Check the YAML generated to see how a CAPI cluster looks like.
```
clusterctl config cluster my-cluster --kubernetes-version v1.18.12 --control-plane-machine-count=3 --worker-machine-count=2 > manifests/cluster.yaml
```

This generates a bunch of manifests that define the form and configuration of the cluster. You can tune those values depend on the necessities (like adding a new feature flag). You can submit the cluster manifests to the Management API and wait till new cluster is created.
```
kubectl apply -f manifests/cluster.yaml
```

__Note__: You can also check the status every moment using `clusterctl describe cluster my-cluster -n default`

In the meanwhile we can generate the kubeconfig of our new cluster using though the cluster is not yet up.
```
clusterctl get kubeconfig my-cluster > /tmp/k.yaml
```

### Create an app


At the same time you had submitted the request for the cluster creation, you can deploy all tooling or addons for that cluster (to become a real platform). Let's do it here we are going to install Prometheus (eventually) on the cluster.

The App operator uses behind the scene helm, and needs to pull the chart package from a helm repository. So before applying our toolings manifests, let's define a catalog with a reference to the repository. Here in the example we use a public Giant Swarm catalog but you can use other.
```
kubectl apply -f app-operator/catalog.yaml
```

The second step would be push the kubeconfig of our new cluster to a secret so the new app operator can access the cluster API.
```
kubectl create secret generic -n giantswarm my-cluster-config --from-file=value=/tmp/k.yaml
```

And finally we need to create the chart operator deployment, which install the operator running on the target cluster and take cares of reconcile all the apps deployed.
```
kubectl apply -f app-operator/chart-operator.yaml
```

The first App to install will be a CNI. This a requirement all Kubernetes clusters need in order to make pod communication possible. In CAPI it does not come with the installation so we will install a calico app like
```
kubectl apply -f manifests/calico-app.yaml
```

From this moment, we can create App custom resources in the fresh cluster. In this case we will deploy Prometheus operator deployment. This will make the app operator to create a new resource in the target cluster, called `chart`, which will be used for the chart operator running in that cluster to make sure the app get installed properly.
```
kubectl apply -f manifests/prometheus-app.yaml
```

### Create a S3 bucket

Finally let's add a manifest that defines a S3 bucket with name `kcd-spain` so we could use it in our platform as object storage.
```
kubectl apply -f manifests/bucket.yaml
```
