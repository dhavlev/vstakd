##### create eks cluster

cat <<EoF> ~/eks.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: cluster-1
  region: us-east-1

nodeGroups:
  - name: ng-1
    labels:
      nodegroup-type: nodegroup-1
      app: eks
    instanceType: t2.medium
    desiredCapacity: 2
    ssh:
      allow: true
      publicKeyName: eks
    minSize: 2
    maxSize: 3
    privateNetworking: false
    iam:
      withAddonPolicies:
        autoScaler: true

availabilityZones: ["us-east-1a", "us-east-1b"]
EoF

eksctl create cluster -f  ~/eks.yaml

## helm setup
cd && curl https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz -o helm-v2.11.0-linux-amd64.tar.gz
tar -zxvf helm-v2.11.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
sleep 60s

#### Istio Setup
cd ~/istio-1.1.7 && helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
sleep 60s
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
helm install install/kubernetes/helm/istio --name istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-demo.yaml --set tracing.enabled=true --set tracing.provider=zipkin
#kubectl label namespace default istio-injection=enabled
#kubectl get namespace -L istio-injection
sleep 60s

#### Installing Ingress
cat > ~/ingressValues.yaml <<EOF
controller:
  replicaCount: 2
  config:
    use-proxy-protocol: "true"
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: '*'
EOF

helm install --name ingress --namespace ingress -f ~/ingressValues.yaml stable/nginx-ingress

sleep 30s
#### Jenkins Setup
cat <<EoF> ~/jenkinValues.yaml

persistence:
  enabled: false
master:
  jenkinsUriPrefix: "/jenkins"
  serviceType: ClusterIP
  ingress:
    enabled: true
    # For Kubernetes v1.14+, use 'networking.k8s.io/v1beta1'
    apiVersion: "extensions/v1beta1"
    labels: {}
    annotations:
      kubernetes.io/ingress.class: nginx
      #kubernetes.io/tls-acme: "true"
    # Set this path to jenkinsUriPrefix above or use annotations to rewrite path
    path: "/jenkins"
    # configures the hostname e.g. jenkins.example.com
    hostName: #ingresshostname
    tls:
    # - secretName: jenkins.cluster.local
    #   hosts:
    #     - jenkins.cluster.local
  installPlugins:
    - workflow-api:2.35
    - kubernetes:1.16.0
    - workflow-job:2.32
    - workflow-aggregator:2.6
    - credentials-binding:1.19
    - git:3.10.0
    - blueocean:1.14.0
    - dashboard-view:2.10
    - build-name-setter:2.0.1
    - config-file-provider:3.6
    - embeddable-build-status:2.0.1
    - rebuild:1.31
    - ssh-agent:1.17
    - throttle-concurrents:2.0.1
    - nodejs:1.3.2
    - checkstyle:4.0.0
    - cobertura:1.14
    - htmlpublisher:1.18
    - junit:1.28
    - warnings-ng:5.1.0
    - xunit:2.3.5
    - build-pipeline-plugin:1.5.8
    - conditional-buildstep:1.3.6
    - jenkins-multijob-plugin:1.32
    - parameterized-trigger:2.35.2
    - copyartifact:1.42.1
    - git-parameter:0.9.11
    - github:1.29.4
    - matrix-project:1.14
    - role-strategy:2.11
    - active-directory:2.16
    - emailext-template:1.1
    - publish-over-ssh:1.20.1
    - ssh:2.6.1
    - periodicbackup:1.5
    - thinBackup:1.9
    - jobConfigHistory:2.22
    - simple-theme-plugin:0.5.1
    - cucumber-testresult-plugin:0.10.1
    - jacoco:3.0.4
    - nodelabelparameter:1.7.2
    - jenkinswalldisplay:0.6.34
    - golang:1.2
    - audit-trail:2.5
    - saferestart:0.3
    - pipeline-utility-steps:2.3.0
EoF

export ingresshostname=$(echo $(kubectl get svc ingress-nginx-ingress-controller -n ingress -o jsonpath='{ .status.loadBalancer.ingress[0].hostname }'))
sed -i "s/#ingresshostname/$ingresshostname/g" ~/jenkinValues.yaml
helm upgrade --install my-jenkins stable/jenkins -f ~/jenkinValues.yaml --namespace tooling

#### Install Kiali Ingress
cat > ~/kiali-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  labels:
    app: kiali
  name: kiali
  namespace: istio-system
spec:
  rules:
  - host: #ingresshostname
    http:
      paths:
      - backend:
          serviceName: kiali
          servicePort: 20001
        path: /kiali
EOF
export ingresshostname=$(echo $(kubectl get svc ingress-nginx-ingress-controller -n ingress -o jsonpath='{ .status.loadBalancer.ingress[0].hostname }'))
sed -i "s/#ingresshostname/$ingresshostname/g" ~/kiali-ingress.yaml
kubectl create -f ~/kiali-ingress.yaml

#### Install Jaeger Ingress
cat > ~/jaeger-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  labels:
    app: jaeger
  name: jaeger
  namespace: istio-system
spec:
  rules:
  - host: #ingresshostname
    http:
      paths:
      - backend:
          serviceName: tracing
          servicePort: 80
        path: /jaeger
EOF

export ingresshostname=$(echo $(kubectl get svc ingress-nginx-ingress-controller -n ingress -o jsonpath='{ .status.loadBalancer.ingress[0].hostname }'))
sed -i "s/#ingresshostname/$ingresshostname/g" ~/jaeger-ingress.yaml
kubectl create -f ~/jaeger-ingress.yaml

#### Install Zipkin Ingress
cat > ~/zipkin-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  labels:
    app: zipkin
  name: zipkin
  namespace: istio-system
spec:
  rules:
  - host: #ingresshostname
    http:
      paths:
      - backend:
          serviceName: zipkin
          servicePort: 9411
        path: /zipkin
EOF

export ingresshostname=$(echo $(kubectl get svc ingress-nginx-ingress-controller -n ingress -o jsonpath='{ .status.loadBalancer.ingress[0].hostname }'))
sed -i "s/#ingresshostname/$ingresshostname/g" ~/zipkin-ingress.yaml
kubectl create -f ~/zipkin-ingress.yaml

#### Create Secrets
# Amend values for docker 'docker-config-secret' and uncomment below line
#kubectl create secret docker-registry docker-config-secret --docker-server=https://index.docker.io/v1/ --docker-username=your-username --docker-password=your-password --docker-email=my-email@provider.com --namespace tooling
kubectl create secret generic kube-secret --from-file=config=.kube/config --namespace tooling
kubectl create secret generic aws-secret --from-file=config=.aws/config --from-file=credentials=.aws/credentials --namespace tooling

### Install Gateway and Virtual service
cat > ~/istio-ingress.yaml <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: voting-app-gw
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: voting-app-vs
spec:
  hosts:
  - "*"
  gateways:
  - voting-app-gw
  http:
  - match:
    - uri:
        prefix: /vote
    route:
    - destination:
        host: vote.voting-app-vote.svc.cluster.local
        port:
          number: 5000
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: result.voting-app-result.svc.cluster.local
        port:
          number: 5001
EOF

kubectl create -f ~/istio-ingress.yaml -n istio-system

### View Nginx Ingress URL
kubectl get svc -n ingress

### View Istio Ingress URL
kubectl get svc -n ingress
echo $(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{ .status.loadBalancer.ingress[0].hostname }')


### Get Jenkins Password
printf $(kubectl get secret --namespace tooling my-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo