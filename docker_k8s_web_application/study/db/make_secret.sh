#! /bin/bash
kubectl create secret generic mongo-secret \
--from-literal=root_username=admin \
--from-literal=root_password=Passw0rd \
--from-file=./keyfile
