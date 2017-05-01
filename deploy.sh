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


