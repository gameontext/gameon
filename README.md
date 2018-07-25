# gameon: The Root Repository / Quick start developers guide.

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

        $ cd gameon                  # cd into the project directory

3. (Optional / Docker Compose only) Use Vagrant for your development environment
   1. Install Vagrant
   2. `vagrant up` (likely with `--provider=virtualbox`)
   3. `vagrant ssh`
   4. use `pwd` to ensure you're in the `/vagrant` directory.

   * Notes:
      * the Vagrantfile updates the .bashrc for the vagrant user to set `DOCKER_MACHINE_NAME=vagrant` to tweak script behavior for use with vagrant.
      * VM provisioning will perform the next two (applicable) steps on your behalf.

4. (Kubernetes only) [Create or retrieve credentials for your cluster](kubernetes/README.md#set-up-a-kubernetes-cluster)

5. Set up required keystores and environment variables. This step also pulls the initial images required for running the system.

        $ ./go-admin.sh choose       # choose Docker Compose or Kubernetes
        $ eval $(./go-admin.sh env)  # set aliases for admin scripts
        $ alias go-run               # confirm path  (docker or kubernetes)
        $ go-admin setup

    Note: it is safe to run `setup` again, e.g. to check dependencies, or regenerate files if IP addresses change

6. Start the game (supporting platform and core services):

        $ go-admin up

7. Wait for the game to start. This will vary between Docker Compose and Kubernetes approaches. The result of `go-admin up` will tell you what to try next.

8. **Carry on with [building your rooms](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/createRoom.html)!**

9. Stop / Clean up

        $ go-admin down


## Core Service Development (Optional)

If you want to contribute to the game's core services, no worries! Assuming you've performed the steps above at least once (and using the `map` service as an example):

1. Change to the gameon directory, set aliases to save typing

        $ cd gameon                  # cd into the project directory
        $ eval $(./go-admin.sh env)  # set aliases for admin scripts
        $ alias go-run               # confirm path  (docker or kubernetes)


2. Obtain the source for the project that you want to change. The easiest way is to take advantage of [git submodules](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/git.html).

        $ git submodule init map
        $ git submodule update map

Updating the game environment once you've made changes varies by deployment:
* [Iterative development with Docker Compose](docker/README.md#iterative-development-with-docker-compose)
* [Iterative development with Kubernetes](kubernetes/README.md#iterative-development-with-kubernetes)

----

## Notes

### Supporting 3rd party auth

3rd party authentication (twitter, github, etc.) will not work locally, but the anonymous/dummy user will. If you want to test with one of the 3rd party authentication providers, you'll need to set up your own tokens to do so.

* Docker: `./docker/gameon.env`
* Kubernetes (files present after setup):
    - `./kubernetes/kubectl/configmap.yaml`
    - Using helm: `./kubernetes/chart/gameon-system/values.yaml`

## Contributing

Want to help! Pile On!

[Contributing to Game On!](https://github.com/gameontext/gameon/blob/master/CONTRIBUTING.md)
