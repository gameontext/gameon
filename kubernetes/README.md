# Deploying core game services in kubernetes

Obtain the source for this repository:
* HTTPS: git clone https://github.com/gameontext/gameon.git
* SSH: git clone git@github.com:gameontext/gameon.git

Start with:

        $ cd gameon                  # cd into the project directory
        $ ./go-admin.sh choose 2     # choose Kubernetes
        $ eval $(./go-admin.sh env)  # set aliases for admin scripts
        $ alias go-run               # confirm kubernetes/go-run.sh

Instructions below will reference `go-run`, the alias created above. Feel free to invoke `./kubernetes/go-run.sh` directly if you prefer.

The `go-run.sh` and `k8s-functions` scripts encapsulate setup and deployment of core game services to kubernetes. Please do open the scripts to see what they do! We opted for readability over shell script-fu for that reason.

## Prerequisites

* [Docker](https://docs.docker.com/install/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://docs.helm.sh/using_helm/#installing-helm) (optional)

## General bring-up instructions

1. [Create or retrieve credentials for your cluster](#set-up-a-kubernetes-cluster)

2. Setup your cluster for the game:

        $ go-run setup

    The `setup` stage will prepare your kubernetes cluster. It will ask you if you want to use istio, and it will ask if you want to use helm. It will then check dependencies, verify that your kubernetes cluster exists, and generate resources based on attributes of your cluster.

    Note: it is safe to run `setup` again at any time, for sanity or because you want to try something else (e.g. istio or helm or both or neither).

    If your cluster IP changes (or you have made changes to some templated files and want to start over), use:

        $ go-run reset

3. Start the game

        $ go-run up

    This step will create a `gameon-system` namespace and a generic kubernetes secret containing a self-signed SSL certificate.

    All core game services will be started in the `gameon-system` namespace. To query or observe game services, the namespace will need to be specified on the command line, e.g.  `kubectl -n gameon-system ...`. Two shortcuts have been created in the `go-run` script to make this easier:
        * `go-run k` for `kubectl`, e.g. `go-run k get pods`
        * `go-run i` for `istioctl`, e.g. `go-run i get virtualservices`.

4. Wait for services to be available

        $ go-run wait

5. Visit your external cluster IP address

6. **Carry on with [building your rooms](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/createRoom.html)!**

7. Stop / Clean up the game

        $ go-run down

## Iterative development with Kubernetes

We'll assume for the following that you want to make changes to the map service, and are continuing with the git submodule created in the [common README.md](../README.md#core-service-development-optional).

1. (Minikube) If you are using minikube, switch to that as your docker host

      $ eval $(minikube docker-env)

2. Checkout your own branch (or add an additional remote for your fork) using standard git commands:

      $ cd map
      $ git checkout -b mybranch

3. Make your changes, and rebuild the service and the docker image for the modified project
  * From the map directory:

          $ ./gradlew build --rerun-tasks
          $ ./gradlew image

  * Via `go-run`

          $ go-run rebuild map

    Note: the `go-run` command will rebuild any of the submodules, even those that are not java/gradle-based.

4. See [Updating images with Kubernetes metadata](#updating-images-with-kubernetes-metadata) or [Updating images with Helm](#updating-images-with-helm) for the required next steps to get the new image running in your kubernetes cluster.

### Updating images with Kubernetes

After an initial deployment of game resources (e.g. via `go-run up`, `kubectl apply ... `, or `helm install`), we can change the image kubernetes is using for the deployment. Continuing on with our revisions to map _while sharing the docker host with minikube_:

      ## ensure :latest tag exists (per above), note image id
      $ docker images gameontext/gameon-map
      ## Confirm map deployment
      $ kubectl -n gameon-system get deployments
      ## Update imagePullPolicy to "Never", and image tag to :latest
      $ kubectl -n gameon-system edit deployment/map

After saving the edited deployment, you should be able to verify that the map deployment was updated to use the built container using the following:

      $ docker ps --filter ancestor=_latestImageId_

Alternately, you can make the same changes to the deployment metadata defined in the kubernetes/kubectl directory to make them persistent across restarts. Once the file has been edited, apply the changes:

      $ kubectl apply -f kubernetes/kubectl/map.yaml

The downside of this approach is that you have to be careful not to check these changes in. ;)

### Updating images with Helm

If you're using helm, you can edit `values.yaml` to persist changes to the image tag or the image pull policy. `values.yaml` is a generated file, so there won't be any warnings from git about uncommitted changes on this path.

1. Open `kubernetes/chart/values.yaml`, find the service you want to update. Set the tag to latest, and the pull policy to Never.

        # map service
        - serviceName: map
          servicePort: 9080
          path: /map
          image: gameontext/gameon-map:latest
          imagePullPolicy: Never
          readinessProbe:
            path: /map/v1/health
            initialDelaySeconds: 40

2. Delete and re-install the helm chart (could upgrade the chart version, but we'll opt for scorched earth for safety):

        $ go-run down
        $ go-run up

  Note: `go-run` will display the invoked `helm` and `kubectl` commands.

### Notes about image tags and imagePullPolicy

By default, docker builds images tagged with :latest. Our images are published to docker hub, and a :latest image does exist there.

Also by default, Kubernetes will apply imagePullPolicy=Always to images tagged with :latest unless a different pull policy is specified.

Because we're shaing the minikube docker host in this example, we want to set the imagePullPolicy to Never AND set the image tag to :latest after we've built a new :latest image.

When you aren't using minikube (which means you can't safely share the docker host), you need to go through a docker registry. Each node in this case will have its own cache. To ensure your new shiny images are used, you'll want to update the image to specifically reference what you're pushing to a docker registry, and to set an imagePullPolicy of `Always`.


## Viewing application logs in Kubernetes





---

## Set up a Kubernetes cluster

`kubectl` needs to be able to talk to a Kuberenetes cluster! You may have one already, in which case, all you need to do is make sure `kubectl` can work with it.

* [Minikube](#minikube) -- local development cluster
* [Minishift](#minishift) -- local development cluster (OpenShift 3.x)
* [IBM Cloud Kubernetes](#ibm-cloud-kubernetes)

### Minikube

If you already have a configured minikube instance, skip to step 3.

1. [Install minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)

2. Start Minikube:

        $ minikube start --memory 8192

3. Ensure the `minikube` context is current context for `kubectl`

        $ kubectl config set-context minikube

4. Follow the [general bring-up instructions](#general-bring-up-instructions)

    **Note: the script detects that minikube** is in use, and uses `minikube ip` to figure out the cluster's external IP address. The script will also enable the minikube ingress addon.

5. (optional) Use `minikube dashboard` to inspect the contents of the `gameon-system` namespace.

## Minishift

If you already have a configured minishift instance, skip to step 3.

1. [Install minishift]() to prepare minishift resources

2. Start Minishift. Here is an example that allocates (fairly generous) resources to the single node:

        $ minishift start --cpus 4 --disk-size 40g --memory 16384

3. Login as `admin` with password `admin`.

        $ oc login -u admin -p admin

    If you are asued about insecure connections, say yes unless you have already configured signed certificates.

    You are now logged in as the `admin` user.

3. Verify `kubectl` can connect to your cluster:

        $ kubectl cluster-info

### IBM Cloud Kubernetes

If you already have a configured cluster, skip to step 3.

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

2. Configure `kubectl` to talk to your cluster

        $ eval $(bx cs cluster-config <cluster-name> | grep "export KUBECONFIG")

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
    Ingress secret:	anthony-test</b>
    Workers:		2
    Version:		1.7.4_1506* (1.8.6_1504 latest)
    </pre>

    Store those in the environment:

        $ go-run host
        Enter ingress hostname (or subdomain): <paste ingress subdomain>
        Enter ingress secret (or enter if none): <paste ingress secret>

    This creates a `.gameontext.kubernetes` file containing information about your cluster.

5. Follow the [general bring-up instructions](#general-bring-up-instructions)
