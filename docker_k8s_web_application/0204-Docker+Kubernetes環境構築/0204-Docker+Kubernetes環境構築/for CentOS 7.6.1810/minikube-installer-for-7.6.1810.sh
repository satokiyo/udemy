#! /bin/sh

# Install "Docker"
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y \
  docker-ce-19.03.1 \
  docker-ce-cli-19.03.1 \
  containerd.io

systemctl enable docker
systemctl start docker

# Install "kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.1/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

# Install "minikube"
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.2.0/minikube-linux-amd64
chmod +x minikube
install minikube /usr/local/bin
rm -f minikube

# stop firewall
systemctl disable firewalld
systemctl stop firewalld

# Add addons
minikube start --vm-driver=none
minikube addons enable ingress

