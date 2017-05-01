#!:/bin/bash

source ./env.sh

function preseed_staging() {
cat << EOF
STAGING SERVER (DIRECT VIRTUAL MACHINE) DIRECTIONS:
  1. Configure a static IP address directly on the VM
     su
     <enter password>
     nano /etc/network/interfaces

		iface eth0 inet static
  		address ${SERVER_IP}
  		netmask 255.255.255.0
  		gateway 192.168.1.1

  2. Install sudo
     apt-get update && apt-get install -y -q sudo

  3. Add the user to the sudo group
     adduser ${SSH_USER} sudo

  4. Run the commands in: $0 --help
     Example:
       ./deploy.sh -a
EOF
}

function configure_sudo() {
	echo "Configuring passwordless sudo..."
	scp "sudo/sudoers" "${SSH_USER}@${SERVER_IP}:/tmp/sudoers"
	ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo chmod 440 /tmp/sudoers
sudo chown root:root /tmp/sudoers
sudo mv /tmp/sudoers /etc
	'"

	echo "success!"
}

function add_ssh_key() {
  echo "Adding SSH key..."
  cat "$HOME/.ssh/id_rsa.pub" | ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
mkdir /home/${KEY_USER}/.ssh
cat >> /home/${KEY_USER}/.ssh/authorized_keys
    '"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
chmod 700 /home/${KEY_USER}/.ssh
chmod 640 /home/${KEY_USER}/.ssh/authorized_keys
sudo chown ${KEY_USER}:${KEY_USER} -R /home/${KEY_USER}/.ssh
  '"
  echo "done!"
}

function configure_secure_ssh() {
  echo "Configuring secure SSH..."
  scp "ssh/sshd_config" "${SSH_USER}@${SERVER_IP}:/tmp/sshd_config"
  ssh -t "${SSH_USER}:${SERVER_IP}" bash -c "'
sudo chown root:root /tmp/sshd_config
sudo mv /tmp/sshd_config /etc/ssh
sudo systemctl restart ssh
  '"
  echo "done!"
}

function install_docker() {
  echo "Configuring Docker v${1}..."
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo apt-get update
sudo apt-get install -y -q libapparmor1 aufs-tools ca-certificates libltdl7
wget -O "docker.deb https://apt.dockerproject.org/repo/pool/main/d/docker-engine/docker-engine_${1}.0~ce-0~debian-jessie_amd64.deb"
sudo dpkg -i docker.deb
rm docker.deb
sudo usermod -aG docker "${KEY_USER}"
  '"
  echo "done!"
}

function configure_firewall() {
  echo "Configuring iptables firewall..."
  scp "iptables/rules-save" "${SSH_USER}@${SERVER_IP}:/tmp/rules-save"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo mkdir -p /var/lib/iptables
sudo mv /tmp/rules-save /var/lib/iptables
sudo chown root:root -R /var/lib/iptables
  '"
  echo "done!"
}

function provision_server() {
  configure_sudo
  echo "-----------"
  add_ssh_key
  echo "-----------"
  configure_secure_ssh
  echo "-----------"
  install_docker ${1}
  echo "-----------"
  configure_firewall
  echo "-----------"
}

function help_menu() {
cat << EOF
Usage: ${0} (-h | -S | -u | -k | -s | -d [docker_ver] | -l | -g | -f | -a [docker_ver])

ENVIRONMENT VARIABLES:
  SERVER_IP        IP address to work on, ie. staging or production
                   Defaulting to ${SERVER_IP}

  SSH_USER         User account to ssh and scp in as
                   Defaulting to ${SSH_USER}

  KEY_USER         User account linked to the SSH key
                   Defaulting to ${KEY_USER}

  DOCKER_VERSION   Docker version to install
                   Defaulting to ${DOCKER_VERSION}

  OPTIONS:
    -h|--help                 Show this message
    -S|--preseed-staging      Preseed intructions for the staging server
    -u|--sudo                 Configure passwordless sudo
    -k|--ssh-key              Add SSH key
    -s|--ssh                  Configure secure SSH
    -d|--docker               Install Docker
    -g|--git-init             Install and initialize git
    -f|--firewall             Configure the iptables firewall
    -a|--all                  Provision everything except preseeding

    EXAMPLES:
      Configure passwordless sudo:
      $ deploy -u

      Add SSH key:
      $ deploy -k

      Configure secure SSH:
      $ deploy -s

      Install Docker v${DOCKER_VERSION}:
      $ deploy -d

      Configure the iptables firewall:
      $ deploy -f

      Configure everything together:
      $ deploy -a
EOF
}

while [[$# > 0]]
do
  case "${1}" in
    -S|--preseed-server)
    preseed_staging
    shift
    ;;
    -u|--configure-sudo)
    configure_sudo
    shift
    ;;
    -k|--add-ssh-key)
    add_ssh_key
    shift
    ;;
    -s|--secure-ssh)
    configure_secure_ssh
    shift
    ;;
    -d|--install-docker)
    install_docker "${2:-${DOCKER_VERSION}}"
    shift
    ;;
    -f|--configure-firewall)
    configure_firewall
    shift
    ;;
    -a|--provision-server)
    provision_server "${2:-${DOCKER_VERSION}}"
esac
shift
done
