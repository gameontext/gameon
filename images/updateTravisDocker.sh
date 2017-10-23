#!/bin/bash
# https://gist.github.com/marcbachmann/16574ba8c614bb3b78614a351f324b86

## Update Docker
sudo apt-get update
sudo apt-get install -o Dpkg::Options::="--force-confold" --force-yes -y docker-ce
sudo rm /usr/local/bin/docker-compose

## Update Docker Compose
GHRELEASES=`curl -w "%{url_effective}\n" -I -L -s -S https://github.com/docker/compose/releases/latest -o /dev/null | sed 's/\/tag\//\/download\//'`
curl -L $GHRELEASES/docker-compose-`uname -s`-`uname -m` > docker-compose
chmod +x docker-compose
sudo mv docker-compose /usr/local/bin

## Echo versions
docker --version
docker-compose --version
