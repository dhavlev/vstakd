# vstakd
This repository contains instruction for setting up K8s cluster and setting up CI &amp; CD pipeline on top of it

## Overview
This is my personal project where I am trying to setup Jenkins Pipeline for web application on top of Kubernetes Cluster

### Components - tools
1. Cloud - AWS, AWSCLI, AWS IAM Authentication
2. Kubernetes Cluster - kubectl, eksctl, istio
3. Jenkins - Helm Charts
4. Pipeline - Jenkins Shared Library
5. Web Application - Voting App (5 tier application)

### Pre-requisites 1 - Setting up Core Components
1. Install AWSCLI
2. Install AWS IAM Authentication
3. Install kubectl
4. Install eksctl
6. Install Helm

### Pre-requisites 2 - Preparing environment to host Web Application
1. Install Istio
2. Install Jenkins

### Pre-requisites 3 - Preparing Jenkins
1. Install charts for db
2. Install Charts for redis
3. Create Pipeline - Worker
4. Create Pipeline - Vote
5. Create Pipeline - Result

### Action
1. Pipeline responsible for CI and builds docker image and stored in docker hub account
2. Deployment happers based on configuration in Jenkinsfile choosing appropriate helm charts for deployment