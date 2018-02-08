# Deploying core game services in kubernetes

For the following instructions, we'll assume you've either cloned the repo
or downloaded and extracted a zip of its contents.

Start with:

        $ cd gameon                  # cd into the project directory
        $ ./go-admin.sh choose 2     # choose Kubernetes
        $ eval $(./go-admin.sh env)  # set aliases for admin scripts
        $ alias go-run               # confirm kubernetes/go-run.sh

Instructions below will reference `go-run`, the alias created above. Feel free to invoke `./kubernetes/go-run.sh` directly if you prefer.

The `go-run.sh` script encapsulates the operations needed to deploy core game services to kubernetes. Please do open the script to see what the steps do! We opted for readability over shell script-fu for that reason.

## Prerequisites

* [Docker](https://docs.docker.com/install/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## General bring-up instructions

1. Create your cluster (see sections below)
    * [Deploy locally with minikube](deploy-in-ibm-cloud-kubernetes)
    * [Deploy in IBM Cloud Kubernetes](deploy-in-ibm-cloud-kubernetes)

2. Setup your cluster:

        $ go-run setup

    This will ensure you have the right versions of applications we use, create a `gameon-system` name space, create a cerficate for signing JWTs, and create a generic kubernetes secret containing that certificate.

3. Bring up your cluster
    * With kubectl

            $ go-run up

    * With helm

            $ helm init
            $ helm install --name go-system ./kubernetes/chart/gameon-system/

4. Wait for services to be available

        $ go-run wait

4. Visit your external cluster IP address

5. Bring down your clusters

    * With kubectl

            $ go-run down

    * With helm

            $ helm list
            $ helm delete --purge go-system

## Deploy locally with minikube


1. [Install minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)

2. Create a minikube cluster:

        $ minikube start --memory 8192

3. Follow the [general bring-up instructions](#general-bring-up-instructions)

    Note: the script detects that minikube is in use, and uses `minikube ip` to figure out the cluster's external IP address. The script will also enable the minikube ingress addon.

4. (optional) Use `minikube dashboard` to inspect the contents of the `gameon-system` namespace.


## Deploy in IBM Cloud Kubernetes


1. You will need to create a cluster and install the IBM Cloud CLI.

    Provisioning clusters can time some time, so if you don't have the CLI installed yet, create the cluster with the GUI first, then install the CLI.
    - Install the [IBM Cloud Container Service CLI](https://console.bluemix.net/docs/containers/cs_cli_install.html#cs_cli_install)
    - [Create a cluster with the GUI](https://console.bluemix.net/docs/containers/cs_clusters.html#clusters_ui)
    - [Create a cluster with the CLI](https://console.bluemix.net/docs/containers/cs_clusters.html#clusters_cli)

    Both the GUI and the CLI will provide instructions for gaining access to your cluster (logging into the CLI and setting the appropriate cluster region).

    **Note**: Using Ingress services requires a standard cluster with at least two nodes.

2. Check on the deployment status of your cluster

        $ bx cs clusters

    You should get something like this:

    <pre>
    OK
    Name     ID                                 State       Created          Workers   Location   Version
    gameon   410e3fd70a3e446999213e904641a0da   deploying   11 minutes ago   1         mil01      1.8.6_1505
    </pre>

    When the state changes from `deploying` to `normal`, your cluster is ready for the next step.

2. Enable `kubectl` to talk to your cluster

        $ bx cs cluster-config <cluster_name_or_id>

    You should get something like this:

        export KUBECONFIG=/Users/<user_name>/.bluemix/plugins/container-service/clusters/<cluster_name>/kube-config-prod-dal10-<cluster_name>.yml

    Execute that command to allow `kubectl` to work with your cluster.

3. Verify `kubectl` can connect to your cluster:

        $ kubectl cluster-info

4. Find the **Ingress subdomain** and **Ingress secret** for your cluster

        $ bx cs cluster-get <your-cluster-name>

    You should get something like this:

    <pre>
    Retrieving cluster anthony-test...
    OK

    Name:			anthony-test
    ID:			bbdb1ff6a36846e9b2dfb522a07005af
    State:			normal
    Created:		2017-10-09T21:43:56+0000
    Datacenter:		dal10
    Master URL:		https://qq.ww.ee.rr:qwer
    <b>Ingress subdomain:	anthony-test.us-south.containers.mybluemix.net
    Ingress secret:		anthony-test</b>
    Workers:		2
    Version:		1.7.4_1506* (1.8.6_1504 latest)
    </pre>

    Store those in the environment:

        $ go-run host
        Enter ingress hostname (or subdomain): <paste ingress subdomain>
        Enter ingress secret (or enter if none): <paste ingress secret>

    This creates a `.gameontext.kubernetes` file used to remember hosts

5. Follow the [general bring-up instructions](#general-bring-up-instructions)
