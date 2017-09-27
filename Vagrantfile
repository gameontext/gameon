# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.define "gameontext" do |vm|
  end
  config.vm.provider "virtualbox" do |v|
    v.memory = 3072
    v.cpus = 2
    v.name = "gameontext"
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
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

    echo 'Installing Git & Curl'
    apt-get install -y \
      git \
      curl \
      openjdk-8-jdk

    echo 'Set up HTTPS repository'
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
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
    curl -sSL https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    echo 'Add vagrant to docker group'
    usermod -aG docker vagrant

    ls -al /var/run/docker.sock
    chgrp docker /var/run/docker.sock
    chmod 775 /var/run/docker.sock

    if /usr/local/bin/bx > /dev/null
    then
      echo 'Updating Bluemix CLI'
      /usr/local/bin/bx update
    else
      echo 'Installing Bluemix CLI'
      sh <(curl -fssSL https://clis.ng.bluemix.net/install/linux 2>/dev/null)
    fi
  EOT

  # Set environment variable to influence provisioning (if specified for create)
  deployment_cmd = ""
  if ENV['GO_DEPLOYMENT']
    value = ENV['GO_DEPLOYMENT']
    deployment_cmd = <<CMD
echo "export GO_DEPLOYMENT=#{value}" | tee -a /home/vagrant/.profile
CMD
  end
  config.vm.provision :shell, :inline => <<-SCRIPT
#{deployment_cmd}
SCRIPT

  # Run as vagrant user (not yet in docker group): bx plugins, profile script
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

    # Enable Gradle Daemon
    mkdir -p /home/vagrant/.gradle
    touch /home/vagrant/.gradle/gradle.properties
    echo "org.gradle.daemon=true" >> /home/vagrant/.gradle/gradle.properties

    # Indicate this is a vagrant VM
    echo 'export DOCKER_MACHINE_NAME=vagrant' | tee -a /home/vagrant/.profile

    # By default this working directory is mapped to /vagrant,
    # automatically change directories on login
    echo 'cd /vagrant' | tee -a /home/vagrant/.profile

    cd /vagrant
    chmod +x go*.sh docker/go*.sh
  EOT

  # Run as vagrant user: Always start things
  config.vm.provision :shell, privileged: false, run: "always", :inline => <<-EOT
    echo 'To start Game On! :'
    echo '> vagrant ssh'
    echo '> ./go-admin.sh setup'
    echo '> ./go-admin.sh up'
    echo ""
    echo 'To test for readiness: http://127.0.0.1:9980/site_alive'
    echo ""
    echo 'To wait for readiness:'
    echo '> ./docker/go-run.sh wait'
    echo 'To watch :popcorn: : '
    echo '> ./docker/go-run.sh logs'
  EOT

end
