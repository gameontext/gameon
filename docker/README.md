# Deploying core game services using Docker Compose

For the following instructions, we'll assume you've either cloned the repo
or downloaded and extracted a zip of its contents.

Start with:

        $ cd gameon                  # cd into the project directory
        $ ./go-admin.sh choose 1     # choose Docker Compose
        $ eval $(./go-admin.sh env)  # set aliases for admin scripts
        $ alias go-run               # confirm docker/go-run.sh

Instructions below will reference `go-run`, the alias created above. Feel free to invoke `./docker/go-run.sh` directly if you prefer.

The `go-run.sh` and `docker-functions` scripts encapsulate setup and deployment of core game services using Docker Compose. Please do open the scripts to see what they do! We opted for readability over shell script-fu for that reason.

## Prerequisites

* [Docker](https://docs.docker.com/install/)
* [Docker Compose](https://docs.docker.com/compose/install/)

## General bring-up instructions

1. Setup

        $ go-run setup

    This will ensure you have the right versions of applications we use, and create a cerficate for signing JWTs.

3. Start the game

        $ go-run up

    This step will also create a `gameon-system` name space and a generic kubernetes secret containing that certificate.

4. Wait for services to be available

        $ go-run wait

5. Visit your external cluster IP address

6. Stop the game

        $ go-run down


## Iterative development with Docker Compose

If you're messing with core game services locally (we love you!), follow the instructions below.

1. Copy the `docker/docker-compose.override.yml.example` file to `docker/docker-compose.override.yml`, and uncomment the section for the service you want to change:
    ```
    map:
      build:
        context:  map/map-wlpcfg
      volumes:
        - '$HOME:$HOME'
        - 'keystore:/opt/ibm/wlp/usr/servers/defaultServer/resources/security'
    ```
    The volume mapping in the `$HOME` directory is optional. If you're using a runtime like Liberty that supports incremental publish / hot swap, using this volume ensures paths will resolve properly.

    This project is set up to help rebuild initialized git submodules. If you don't want to work with [git submodules](../README.md#core-service-development-optional), update the paths in the `docker/docker-compose.override.yml` to reference where the projects have been extracted. You will have to build the project on your own. Docker Compose will see the updated image in the following steps.

2. Build the project(s) (includes building wars and creating keystores required for local development). You may have different requirements per service (e.g. most require Java 8):

        $ go-run rebuild map

    This will build the project artifacts and the docker container, and will replace the container in the running system.

3. Iterate!
      * For subsequent code changes to the same project:

                $ go-run rebuild map

      * To rebuild multiple projects, specify multiple projects as arguments, e.g.

                $ go-run rebuild map player auth

      * To rebuild all projects, use either:

                $ go-run rebuild

        or

                $ go-run rebuild
