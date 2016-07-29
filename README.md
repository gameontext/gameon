# gameon: The Root Repository / Quick start developers guide.

This is the TL;DR version. For more details/background/links, see: [Getting Started (GitBook)](https://gameontext.gitbooks.io/gameon-gitbook/content/)


## If you just want enough running to support room development

Obtain the source `git clone git@github.com:gameontext/gameon.git` (or HTTPS equivalent)

One time setup, this will ensure that required keystores are setup, and that you have an 
env file suitable for use with docker-compose (whether you're using docker-machine or not).

```
./go-setup.sh
```

This setup step also pulls the initial images required for running the system.

```
./go-platform-services.sh start
```

This will start Game ON platform services (amalgam8, couchdb, and an elk stack!).
These services are configured in `platformservices.yml`.

```
./go-run.sh start
```

The `go-run.sh` script contains shorthand operations to help with starting, stopping, 
and cleaning up after Game ON core services (in `docker-compose.yml`).



## If you want to build and edit core services

Obtain the source: 

```
git clone --recursive git@github.com:gameontext/gameon.git
cd gameon
```

Build/initialize the projects (includes building wars and creating keystores required for local development).
```
./go-build.sh
```

Now we build the docker containers with docker-compose (see [below](#notes))
```
docker-compose build --pull
docker-compose up
```

Game On! is now running locally.
* If you're running a \*nix variant, you can access it at http://127.0.0.1/
* If you're running Mac or Windows, access it using the docker host IP address (see [below](#notes))

## Notes

### Supporting 3rd party auth

3rd party authentication (twitter, github, etc.) will not work locally, but the anonymous/dummy user will. If you want to test with one of the 3rd party authentication providers, you'll need to set up your own tokens to do so.

### Use the right IP address

If you run on an operating system that uses a host VM for docker images (e.g. Windows or Mac), then you need to update some values in `gameon.env` to match the IP address of your host. The host IP address is returned by `docker-machine ip <machine-name>`.

`go-build.sh` will create a customized copy of `gameon.env` for the active DOCKER_MACHINE_NAME, that will perform the substitution to the associated IP address.

### Top-down vs. incremental updates

`docker-compose.override.yml` maps subrepository paths into the docker containers to support live development.

If you prefer a top-down-republish approach, rename `docker-compose.override.yml` to `docker-compose.override.yml.backup` to skip mounting volumes. Re-run `go-build.sh` and the docker-compose build steps to publish the updates.

### Iterative development of Java applications with WDT
We highly recommend using WebSphere Developer Tools (WDT) to work with the Java services contained in the sample. Going along with the incremental publish support provided by the `docker-compose-override.yml` file, there is some (one time) [configuration required to make WDT happy with the docker-hosted applications](https://gameontext.gitbooks.io/gameon-gitbook/content/getting-started/eclipse_and_wdt.html).

## Contributing

Want to help! Pile On! 

[Contributing to Game On!](https://github.com/gameontext/gameon/blob/master/CONTRIBUTING.md)
