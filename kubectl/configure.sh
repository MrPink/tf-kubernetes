#!/usr/bin/env bash

CA_CERT=$(pwd)/../certs/ca.crt
SERVER_KEY=$(pwd)/../certs/kubectl.key
SERVER_CERT=$(pwd)/../certs/kubectl.crt
DOMAIN="example.com"
CLUSTER_NAME="kubernetes"

kubectl config set-credentials default-admin --certificate-authority=${CA_CERT} --client-key=${SERVER_KEY} --client-certificate=${SERVER_CERT}
kubectl config set-cluster $CLUSTER_NAME --server=https://k8-api.$DOMAIN --certificate-authority=${CA_CERT} --user=default-admin
kubectl config use-context $CLUSTER_NAME 
