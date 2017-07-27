# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.provider "virtualbox" do |v|
    v.memory = 3072
    v.cpus = 2
  end
 
  #fix 'stdin is not a tty' output.
  config.vm.provision :shell, inline: "(grep -q -E '^mesg n$' /root/.profile && sed -i 's/^mesg n$/tty -s \\&\\& mesg n/g' /root/.profile && echo 'Ignore the previous error about stdin not being a tty. Fixing it now...') || exit 0;"

  #forward port 80 to the docker host, so we can access game-on's web page.
  config.vm.network(:forwarded_port, guest: 80, host: 9980)
  config.vm.network(:forwarded_port, guest: 443, host: 9943)


  # Run as Root -- install git, latest docker, bx cli
  config.vm.provision :shell, :inline => <<-EOT
    apt-get purge docker docker-engine docker.io

    apt-get update 
    apt-get upgrade -y

    echo 'Installing Git & Curl'
    apt-get install -y git curl

    echo 'Set up HTTPS repository'
    apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"

    echo 'Install Docker CE'
    apt-get update
    apt-get install -y docker-ce

    DOCKER_COMPOSE_VERSION=1.15.0
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose


    apt-get install -y openjdk-8-jdk

    
    if /usr/local/bin/bx > /dev/null
    then
      echo 'Updating Bluemix CLI'
      /usr/local/bin/bx update
    else
      echo 'Installing Bluemix CLI'
      sh <(curl -fsSL https://clis.ng.bluemix.net/install/linux)
    fi

  EOT


  # Run as vagrant user: bx plugins, profile script
  config.vm.provision :shell, privileged: false, :inline => <<-EOT
    PLUGINS=$(bx plugin list)
    if echo $PLUGINS | grep dev
    then
      /usr/local/bin/bx plugin update dev -r Bluemix
    else
      echo 'Installing Bluemix dev plugin'
      /usr/local/bin/bx plugin install dev -r Bluemix
    fi
    if echo $PLUGINS | grep container-service
    then
      /usr/local/bin/bx plugin update container-service -r Bluemix
    else
      echo 'Installing Bluemix container-service plugin'
      /usr/local/bin/bx plugin install container-service -r Bluemix
    fi
    
    if echo $PLUGINS | grep container-registry
    then
      /usr/local/bin/bx plugin update container-registry -r Bluemix
    else
      echo 'Installing Bluemix container-registry plugin'
      /usr/local/bin/bx plugin install container-registry -r Bluemix
    fi
    
    
    # By default this directory is mapped to /vagrant
    # set up shell script.. 

    echo 'cd /vagrant' >> /home/vagrant/.bash_profile
    echo 'export DOCKER_MACHINE_NAME=vagrant' >>  /home/vagrant/.bash_profile

    cd /vagrant
    chmod +x go*.sh
     ./go-setup.sh
  EOT

  # Run as vagrant user: Always start things
  config.vm.provision :shell, privileged: false, run: "always", :inline => <<-EOT
    cd /vagrant

    ./go-platform-services.sh start
    
    echo 'Running rebuild... '
    ./go-run.sh rebuild --nologs all && echo 'Done.'

    
    echo 'OK, GameOn should now be running inside the vagrant vm.. try https://127.0.0.1:9943/ to see if its running.. SSH is also available on port 2222'
  EOT

end
