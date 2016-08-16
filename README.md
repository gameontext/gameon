# gameon: The Root Repository / Quick start developers guide.

This is the TL;DR version. For more details/background/links, see: [Intro to Game On! (GitBook)](https://gameontext.gitbooks.io/gameon-gitbook/content/)

As a prerequisite, make sure [Docker](https://docs.docker.com/engine/installation/) is installed and running.

* [Local room development](#local-room-development)
* [Core game development](#core-game-development)

## Local Room Development

1. Obtain the source for this repository:
  * HTTPS: `git clone https://github.com/gameontext/gameon.git`
  * SSH: `git clone git@github.com:gameontext/gameon.git`

2. Change to the gameon directory
  ```
  cd gameon
  ```

3. One time setup, this will ensure that required keystores are setup, and that you have an
  env file suitable for use with docker-compose (whether you're using docker-machine or not).
  ```
  ./go-setup.sh
  ```
  This setup step also pulls the initial images required for running the system.

4. Start Game ON platform services (amalgam8, couchdb, and an elk stack!).
  These services are configured in `platformservices.yml`.
  ```
  ./go-platform-services.sh start
  ```

5. Start the core Game ON services (Player, Mediator, Map)
  ```
  ./go-run.sh start
  ```
  The `go-run.sh` script contains shorthand operations to help with starting,
  stopping, and cleaning up after Game ON core services (in `docker-compose.yml`).

Game On! is now running locally.
* If you're running a \*nix variant, you can access it at http://127.0.0.1/
* If you're running Mac or Windows, access it using the docker host IP address (see [below](#notes))

Carry on with building your rooms!

## Core Game Development

1. Obtain the source:
  * HTTPS: `git clone https://github.com/gameontext/gameon.git`
  * SSH: `git clone git@github.com:gameontext/gameon.git`

2. Change to the gameon directory
  ```
  cd gameon
  ```

3. One time setup, this will ensure that required keystores are setup, and that you have an
  env file suitable for use with docker-compose (whether you're using docker-machine or not).
  ```
  ./go-setup.sh
  ```
  This setup step also pulls the initial images required for running the system.

4. Start Game ON platform services (amalgam8, couchdb, and an elk stack!).
  These services are configured in `platformservices.yml`.
  ```
  ./go-platform-services.sh start
  ```

5. Build the docker containers (see [below](#notes))
   ```
   ./go-run.sh rebuild
   ```

Game On! is now running locally.
* If you're running a \*nix variant, you can access it at http://127.0.0.1/
* If you're running Mac or Windows, access it using the docker host IP address (see [below](#notes))

## Core Game Development - changing code

Using the [map project](https://github.com/gameontext/gameon-map) as an example,

1. Obtain the source for the project that you want to change.
  ```
  git submodule init map
  git submodule update map
  ```

2. Re-enable the build directive in the docker-compose.yml file.
  ```
  map:
   build: map/map-wlpcfg
   image: gameontext/gameon-map
   volumes:
    - './keystore:/opt/ibm/wlp/usr/servers/defaultServer/resources/security'
  ```

3. Build the project(s) (includes building wars and creating keystores
   required for local development).
   to be deployed.
  ```
  ./go-run.sh rebuild map
  ```

For subsequent code changes to the same project, you just need to execute `go-run.sh rebuild map`.
To rebuild multiple projects, you can specify multiple projects as arguments, eg. `go-run.sh rebuild map player auth`
To rebuild all projects, use `go-run.sh rebuild` or `go-run.sh rebuild all`

## Notes

### Supporting 3rd party auth

3rd party authentication (twitter, github, etc.) will not work locally, but the anonymous/dummy user will. If you want to test with one of the 3rd party authentication providers, you'll need to set up your own tokens to do so (see `gameon.env`)

### Use the right IP address

If you run on an operating system that uses a host VM for docker images (e.g. Windows or Mac), then you need to update some values in `gameon.env` to match the IP address of your host. The host IP address is returned by `docker-machine ip <machine-name>`.

`go-setup.sh` will create a customized copy of `gameon.env` for the active DOCKER_MACHINE_NAME, that will perform the substitution to the associated IP address.

### Iterative development of Java applications with WDT
We highly recommend using WebSphere Developer Tools (WDT) to work with the Java services contained in the sample.

If you favor incremental publish with docker containers, create a `docker-compose-override.yml` file that maps the local development directory
as a volume (see `docker-compose-override.yml.example` for strings to cut and
paste). There is some (one time) [configuration required to make WDT happy with the docker-hosted applications](https://gameontext.gitbooks.io/gameon-gitbook/content/getting-started/eclipse_and_wdt.html).

## Contributing

Want to help! Pile On!

[Contributing to Game On!](https://github.com/gameontext/gameon/blob/master/CONTRIBUTING.md)
