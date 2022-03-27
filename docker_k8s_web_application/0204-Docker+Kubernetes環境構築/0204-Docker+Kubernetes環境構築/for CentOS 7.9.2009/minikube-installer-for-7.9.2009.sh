#! /bin/sh
####################################################
# Discription :
#   Install Docker & Minikube(Kubernetes)
#   for CentOS 7.9.2009
# 
# Usage :
#   $ sudo sh ./minikube-installer-for-7.9.2009.sh
# 
# History :
#   2021/06/20  Update docker v20.10.7, minikube v1.21.0
#
####################################################

# Modify yum.conf
sed -i -e "/timeout\=/d" /etc/yum.conf
sed -i -e "13s/^/timeout=300\n/g" /etc/yum.conf
sed -i -e "/ip_resolve\=/d" /etc/yum.conf
sed -i -e "14s/^/ip_resolve=4\n/g" /etc/yum.conf

# Add .curlrc
cat <<EOF > ~/.curlrc
ipv4
EOF

# --------------------------------------------------
# Install "Docker"
yum install -y \
  yum-utils-1.1.31

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y \
  docker-ce-20.10.7 \
  docker-ce-cli-20.10.7 \
  containerd.io-1.4.6

systemctl enable docker
systemctl start docker

# Modify "Docker" configuration
systemctl stop docker

mkdir -p /etc/docker

DOCKER_IF_NAME=docker0
DOCKER_IF_ADDRESS=$(ip -4 address show ${DOCKER_IF_NAME} | grep inet | awk '{print $2}' | sed -e "s/\/[0-9]*$//")
DOCKER_LOCAL_REGISTRY=${DOCKER_IF_ADDRESS}:5000
cat <<EOF > /etc/docker/daemon.json
{
  "dns": ["8.8.8.8"],
  "insecure-registries": ["${DOCKER_LOCAL_REGISTRY}"]
}
EOF

systemctl start docker

# --------------------------------------------------
# Install conntrack
yum install -y \
  conntrack-tools-1.4.4

# Install "kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.21.2/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv -f ./kubectl /usr/local/bin

# Install "minikube"
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.21.0/minikube-linux-amd64
chmod +x minikube
install minikube /usr/local/bin
rm -f minikube

# stop firewall
systemctl disable firewalld
systemctl stop firewalld

# Docker restart and update DNS settings
systemctl restart docker

# Add addons
/usr/local/bin/minikube config set insecure-registry ${DOCKER_LOCAL_REGISTRY}
/usr/local/bin/minikube start --vm-driver=none
/usr/local/bin/minikube addons enable ingress

