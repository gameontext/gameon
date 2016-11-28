# gameon: The Root Repository / Quick start developers guide.

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

Carry on with [building your rooms](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/createRoom.html)!

-----

## Core Game Development

If you want to contribute to the game's core services, the easiest way is to take advantage of 
[git submodules](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/git.html)

Assuming you've performed the steps above at least once, and using the 
[map project](https://github.com/gameontext/gameon-map) as an example:

1. Change to the gameon directory
  ```
  cd gameon
  ```

2. Obtain the source for the project that you want to change.
  ```
  git submodule init map
  git submodule update map
  ```

3. Copy the `docker-compose.override.yml.example` file to `docker-compose.override.yml`,
   and uncomment the section for the service you want to change
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

3. Build the project(s) (includes building wars and creating keystores
   required for local development)
   to be deployed.
  ```
  ./go-run.sh rebuild map
  ```

4. Iterate!
  * For subsequent code changes to the same project: 
  
    `go-run.sh rebuild map`
    
  * To rebuild multiple projects, specify multiple projects as arguments, e.g.
  
    `go-run.sh rebuild map player auth`
   
  * To rebuild all projects, use either:
  
    `go-run.sh rebuild` or `go-run.sh rebuild all`

----

## Notes

### Supporting 3rd party auth

3rd party authentication (twitter, github, etc.) will not work locally, but the anonymous/dummy user will. If you want to test with one of the 3rd party authentication providers, you'll need to set up your own tokens to do so (see `gameon.env`)

### Use the right IP address

If you run on an operating system that uses a host VM for docker images (e.g. Docker Toolbox on Windows or Mac), then you need to update some values in `gameon.env` to match the IP address of your host. The host IP address is returned by `docker-machine ip <machine-name>`. `go-setup.sh` will create a customized copy of `gameon.env` for the active `DOCKER_MACHINE_NAME`, that will perform the substitution to the associated IP address.

## Contributing

Want to help! Pile On!

[Contributing to Game On!](https://github.com/gameontext/gameon/blob/master/CONTRIBUTING.md)
