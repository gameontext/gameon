# gameon
The Root Repository

GameOn quick start developers guide.. 

Obtain the source
```
git clone --recursive git@github.com:gameontext/gameon.git
cd gameon
```

Build the projects with gradle. (Note this just runs gradle build against each subdir, until we write some gradle in the root project for a cleaner solution)
```
./build.sh
```
Now we build the docker containers with docker-compose.

If you just want to run gameon locally, and don't mind rebuilding the docker containers each time, then rename docker-compose.override.yml to docker-compose.override.yml.backup

If you do want to run gameon locally with the code running from an eclipse workspace, then leave the docker-compose.override.yml file there. But we'll need to remove the server.env and bootstrapping.properties files .. as they'll cause us issues (we'll remove these directly from the repositories soon.)

```
docker-compose build
docker-compose up
```
