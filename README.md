# gameon: The Root Repository / Quick start developers guide.

<a href="https://zenhub.com"><img src="https://raw.githubusercontent.com/ZenHubIO/support/master/zenhub-badge.png"></a>

This is the TL;DR version.
* [Local room development](#local-room-development)
* [Core game development](#core-game-development)
* [Additional notes](#notes)

 For more details/background/links, see: 
* [Intro to Game On! (GitBook)](https://book.gameontext.org/)
* [Working with Game On! Locally](https://book.gameontext.org/walkthroughs/local-build.html) for details.

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
      * VM provisioning will perform the next two steps on your behalf. 

4. Set up required keystores and environment variables. This step also pulls the initial images required for running the system. (This action only needs to be run once).
    ```
    ./go-admin.sh setup
    ```

  * This script uses `DEPLOYMENT` to choose between using Docker Compose or Kubernetes for deployment.
    * `DEPLOYMENT=docker-compose` -- Scripts related to provisioning with Docker Compose are in the `docker` directory.
    * Coming Soon: `DEPLOYMENT=kubernetes` -- Scripts related to provisioning with helm and kubernetes are in the `kubernetes` directory. 
    
5. Start the game (supporting platform and core services):
    ```
    ./go-admin.sh up
    ```

6. Wait for the game to start. This will vary between Docker Compose and Kubernetes approaches. `./go-admin.sh up` will tell you what to try next.

7. **Carry on with [building your rooms](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/createRoom.html)!**

8. Stop / Clean up
    ```
    ./go-admin.sh down
    ```


## Core Service Development (Optional)

If you want to contribute to the game's core services, no worries! Assuming you've performed the steps above at least once (and using the `map` service as an example):

1. Change to the gameon directory
    ```
    cd gameon
    ```

2. Set some aliases to save typing: 
    ```
    eval $(./docker/go-run.sh env)
    go-run
    ```

2. Obtain the source for the project that you want to change. The easiest way is to take advantage of [git submodules](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/git.html).
    ```
    git submodule init map
    git submodule update map
    ```

3. Copy the `docker/docker-compose.override.yml.example` file to `docker/docker-compose.override.yml`, and uncomment the section for the service you want to change:
    ```
    map:
      build:
        context:  map/map-wlpcfg
      volumes:
        - '$HOME:$HOME'
        - 'keystore:/opt/ibm/wlp/usr/servers/defaultServer/resources/security'
    ```
    The volume mapping in the `$HOME` directory is optional. If you're using a runtime like Liberty that supports incremental publish / hot swap, using this volume ensures paths will resolve properly.

4. Build the project(s) (includes building wars and creating keystores required for local development) to be deployed. You may have different requirements per service (e.g. most require Java 8):
    ```
    go-run rebuild map
    ```

5. Iterate!
  * For subsequent code changes to the same project:
    ```
    go-run rebuild map
    ```
  
  * To rebuild multiple projects, specify multiple projects as arguments, e.g.
    ```
    go-run rebuild map player auth
    ```

  * To rebuild all projects, use either:
    ```
    go-run rebuild
    ```
    or
    ```
    go-run rebuild all
    ```

----

## Notes

### Supporting 3rd party auth

3rd party authentication (twitter, github, etc.) will not work locally, but the anonymous/dummy user will. If you want to test with one of the 3rd party authentication providers, you'll need to set up your own tokens to do so (see `gameon.env`)

## Contributing

Want to help! Pile On!

[Contributing to Game On!](https://github.com/gameontext/gameon/blob/master/CONTRIBUTING.md)
