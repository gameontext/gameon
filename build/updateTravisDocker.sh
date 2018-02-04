#!/bin/bash

## Update Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y install docker-ce

## Update Docker Compose
GHRELEASES=`curl -w "%{url_effective}\n" -I -L -s -S https://github.com/docker/compose/releases/latest -o /dev/null | sed 's/\/tag\//\/download\//'`
curl -L $GHRELEASES/docker-compose-`uname -s`-`uname -m` > docker-compose
chmod +x docker-compose
sudo mv docker-compose /usr/local/bin

## Echo versions
docker --version
docker-compose --version

