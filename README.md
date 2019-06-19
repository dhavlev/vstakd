# vstakd
This repository contains instruction for setting up K8s cluster and setting up CI &amp; CD pipeline on top of it

## Overview
This is my personal project where I am trying to setup Jenkins Pipeline for web application on top of Kubernetes Cluster

![Architecture diagram](images/architecture.png)

### Components - tools
1. Cloud - AWS, AWSCLI, AWS IAM Authentication
2. Kubernetes Cluster - kubectl, eksctl, istio
3. Jenkins - Helm Charts
4. Pipeline - Jenkins Shared Library
5. Web Application - Voting App (5 tier application)

### Repos & Charts
|     App Name      |                              App Link                              | App Branch |                                       Chart                                       | Chart Branch |                                Comment                                |
| :---------------: | :----------------------------------------------------------------: | :--------: | :-------------------------------------------------------------------------------: | :----------: | :-------------------------------------------------------------------: |
|  voting-app-vote  | [voting-app-vote](https://github.com/dhavlev/voting-app-vote.git)  |   master   |  [chart](https://github.com/dhavlev/helm-charts/tree/voting-app/voting-app-vote)  |  voting-app  |              web application responsible recording vote               |
| voting-app-result | [voting-app-result](https://github.com/dhavlev/voting-app-result)  |   master   | [Chart](https://github.com/dhavlev/helm-charts/tree/voting-app/voting-app-result) |  voting-app  |              web application responsible showing results              |
| voting-app-worker | [voting-app-worker ](https://github.com/dhavlev/voting-app-worker) |   master   | [chart](https://github.com/dhavlev/helm-charts/tree/voting-app/voting-app-worker) |  voting-app  | worker application, read data from redis cache and writes to database |
| voting-app-redis  |  [voting-app-redis](https://github.com/dhavlev/voting-app-redis)   |   master   | [chart](https://github.com/dhavlev/helm-charts/tree/voting-app/voting-app-redis)  |  voting-app  |  contains Jenkinsfile responsible for calling helm charts for redis   |
|   voting-app-db   |       [voting-app-db](https://github.com/dhavlev/voting-app-db)       |   master   |   [chart](https://github.com/dhavlev/helm-charts/tree/voting-app/voting-app-db)   |  voting-app  | contains Jenkinsfile responsible for calling helm charts for database |

### Setup 1
1. System update
2. Kubectl installation
3. Aws iam authentication installation
4. Istio installation
5. Aws cli setup
6. Configure aws profile
   
```
chmod 777 pre1.sh
./pre1.sh
``` 
### Setup 2
1. Creation of EKS cluster
2. Helm installation
3. Instio setup
4. Ingress-nginx setup
5. Jenkins setup
6. Kiali ingress setup
7. Jaegor ingress setup
8. Zipkin ingress setup
9. Secrets - kube-secret and aws-secret
10. Setup Gateway and Virtual service
    
```
chmod 777 pre2.sh
./pre2.sh
``` 
> Please amend docker crdentials in [pre2.sh](pre2.sh)

### Setup 3
1.  Browse Jenkins
### Pre-requisites 4 - Preparing Jenkins
1. Configure global shared library - [jenkins-shared-library](https://github.com/dhavlev/jenkins-shared-library/tree/voting-app)   
   [Screen Print](images/jenkins-shared-library-configuration.PNG)
2. Create Pipeline - db   
3. Create Pipeline - redis
4. Create Pipeline - Vote
5. Create Pipeline - Result
6. Create Pipeline - Worker

### Action
1. Pipeline responsible for CI and builds docker image and stored in docker hub account
2. Deployment happers based on configuration in Jenkinsfile choosing appropriate helm charts for deployment

### Commands
#### docker-config-secret
kubectl create secret docker-registry docker-config-secret --docker-server=https://index.docker.io/v1/ --docker-username=your-username --docker-password=your-password --docker-email=my-email@provider.com --namespace tooling

#### kube-secret
kubectl create secret generic kube-secret --from-file=config=kube-secret --namespace tooling

#### aws-secret
kubectl create secret generic aws-secret --from-file=config=.aws/config --from-file=credentials=.aws/credentials --namespace tooling

### Troubleshooting
1. Unable to schedule jenkins slave
   Make sure k8s secrets are in place for both docker and kube config