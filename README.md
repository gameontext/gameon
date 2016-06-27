# gameon: The Root Repository / Quick start developers guide.

This is the TL;DR version. For more details/background/links, see: [Getting Started (GitBook)](https://gameontext.gitbooks.io/gameon-gitbook/content/)

Obtain the source (SSH preferred, works better with submodules)
```
git clone --recursive git@github.com:gameontext/gameon.git
cd gameon
```

Build/initialize the projects (includes building wars and creating keystores required for local development).
```
./build.sh
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

`build.sh` will create a customized copy of `gameon.env` for the active DOCKER_MACHINE_NAME, that will perform the substitution to the associated IP address.

### Top-down vs. incremental updates

`docker-compose.override.yml` maps subrepository paths into the docker containers to support live development.

If you prefer a top-down-republish approach, rename `docker-compose.override.yml` to `docker-compose.override.yml.backup` to skip mounting volumes. Re-run `build.sh` and the docker-compose build steps to publish the updates.

### Iterative development of Java applications with WDT
We highly recommend using WebSphere Developer Tools (WDT) to work with the Java services contained in the sample. Going along with the incremental publish support provided by the `docker-compose-override.yml` file, there is some (one time) [configuration required to make WDT happy with the docker-hosted applications](https://gameontext.gitbooks.io/gameon-gitbook/content/getting-started/eclipse_and_wdt.html).

## Contributing

Want to help! Pile On! 

[Contributing to Game On!](https://github.com/gameontext/gameon/blob/master/CONTRIBUTING.md)
