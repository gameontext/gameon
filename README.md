# gameon: The Root Repository / Quick start developers guide.

<a href="https://zenhub.com"><img src="https://raw.githubusercontent.com/ZenHubIO/support/master/zenhub-badge.png"></a>

This is the TL;DR version. For more details/background/links, see: [Intro to Game On! (GitBook)](https://gameontext.gitbooks.io/gameon-gitbook/content/)

As a prerequisite, make sure Java 8 is installed, and [Docker](https://docs.docker.com/engine/installation/) is installed and running.

* [Local room development](#local-room-development)
* [Core game development](#core-game-development)
* [Additional notes](#notes)

## Local Room Development

1. Obtain the source for this repository:
  * HTTPS: `git clone https://github.com/gameontext/gameon.git`
  * SSH: `git clone git@github.com:gameontext/gameon.git`

2. Change to the gameon directory
  ```
  cd gameon
  ```

3. (Optional) Use Vagrant for your development environment
  1. Install Vagrant
  2. `vagrant up` (likley with `--provider=virtualbox`)
  3. `vagrant ssh`
  4. use `pwd` to ensure you're in the `/vagrant` directory.

  * Notes:
    * the Vagrantfile updates the .bashrc for the vagrant user to set `DOCKER_MACHINE_NAME=vagrant` to tweak script behavior for use with vagrant.
    * VM provisioning will perform the next two steps on your behalf. To toggle between Kubernetes via minikube and Docker Compose in the Vagrant VM, set the DEPLOYMENT environment variable at provisioning time.

4. Set up required keystores and environment variables. This step also pulls the initial images required for running the system. (This action only needs to be run once).
```
./go-admin.sh setup
```

  * This script uses `DEPLOYMENT` to choose between using Docker Compose or Kubernetes for deployment.
    * `DEPLOYMENT=docker-compose` -- Scripts related to provisioning with Docker Compose are in the `docker` directory.
    * `DEPLOYMENT=minikube` -- Scripts related to provisioning with helm and kubernetes are in the `kubernetes` directory. Local deployment will be via minikube.

5. Start the game (supporting platform and core services):
```
./go-admin.sh up
```
  * When using Docker Compose, this is a two step process, that can be emulated using:
  ```
  ./docker/go-platform-services.sh start
  ./docker/go-run.sh start
  ```

    `./docker/go-run.sh` contains useful short-hand operations for working with docker containers defined by the yml files in the `docker` directory.


### Game On! is now running locally.

When http://127.0.0.1/site_alive returns 200 OK, everything is up and running.

* If you're running a \*nix variant, you can access it at http://127.0.0.1/
* If you're running Mac or Windows, access it using the docker host IP address (see [below](#notes))

Carry on with [building your rooms](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/createRoom.html)!

-----

## Core Game Development

If you want to contribute to the game's core services, no worries!

Assuming you've performed the steps above at least once (and using the `map` service as an example):

1. Change to the gameon directory
  ```
  cd gameon
  ```

2. Obtain the source for the project that you want to change. The easiest way is to take advantage of
[git submodules](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/git.html).
  ```
  git submodule init map
  git submodule update map
  ```

3. Copy the `docker/docker-compose.override.yml.example` file to `docker/docker-compose.override.yml`,
   and uncomment the section for the service you want to change:
  ```
  map:
   build:
     context:  map/map-wlpcfg
   volumes:
    - '$HOME:$HOME'
    - 'keystore:/opt/ibm/wlp/usr/servers/defaultServer/resources/security'
  ```
   The volume mapping in the `$HOME` directory is optional. If you're using a runtime like Liberty
   that supports incremental publish / hot swap, mapping in this volume ensures paths will resolve properly.

4. Build the project(s) (includes building wars and creating keystores
   required for local development) to be deployed.
  ```
  ./docker/go-run.sh rebuild map
  ```

5. Iterate!
  * For subsequent code changes to the same project:

    `./docker/go-run.sh rebuild map`

  * To rebuild multiple projects, specify multiple projects as arguments, e.g.

    `./docker/go-run.sh rebuild map player auth`

  * To rebuild all projects, use either:

    `./docker/go-run.sh rebuild` or `./docker/go-run.sh rebuild all`

----

## Notes

### Supporting 3rd party auth

3rd party authentication (twitter, github, etc.) will not work locally, but the anonymous/dummy user will. If you want to test with one of the 3rd party authentication providers, you'll need to set up your own tokens to do so (see `gameon.env`)

### Use the right IP address

If you run on an operating system that uses a host VM for docker images (e.g. Docker Toolbox on Windows or Mac), then you need to update some values in `gameon.env` to match the IP address of your host. `go-setup.sh` will create a customized copy of `gameon.env` for the active `DOCKER_MACHINE_NAME`, that will perform the substitution to the host IP address returned by `docker-machine ip <machine-name>`.

## Contributing

Want to help! Pile On!

[Contributing to Game On!](https://github.com/gameontext/gameon/blob/master/CONTRIBUTING.md)
