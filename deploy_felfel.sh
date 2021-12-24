#! /bin/bash

# Variables
NAMESPACE='felfel'
HELM_CHART='./felfel'
HELM_RELEASE_NAME='myfelfel'
REDIS_PASSWORD=$REDIS_PASSWORD # this value should be hidden

# Check if minikube is running
running_status=$(minikube status | grep Running)
lines=$(echo $running_status | wc -l)

if [ $lines != 3];
then
  minikube start --driver=none
else
  echo " Minikube is running"
fi

# Install the helm chart
kubectl create ns $NAMESPACE
helm dependency update $HELM_CHART
helm upgrade --install $HELM_RELEASE_NAME $HELM_CHART --namespace $NAMESPACE --set redis.global.redis.password=$REDIS_PASSWORD --set namespace=$NAMESPACE --set ingress.hosts[0].host=$NAMESPACE.local,ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=ImplementationSpecific
helm status $HELM_RELEASE_NAME | grep STATUS


# Set the host and the IP in /etc/hosts

# I have commented these cmds to allow the CICD to succeed
# Please uncomment them if you run localy

# MINIKUBE_IP=$(minikube ip)
# echo "$MINIKUBE_IP $NAMESPACE.local" >> /etc/hosts

