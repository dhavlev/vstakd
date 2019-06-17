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

cd ~/istio-1.1.7 && helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
sleep 10s
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
helm install install/kubernetes/helm/istio --name istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-demo.yaml
kubectl label namespace default istio-injection=enabled
kubectl get namespace -L istio-injection


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

helm install --name ingress --namespace ingress -f ingressValues.yaml stable/nginx-ingress


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
    - workflow-api:2.33
    - kubernetes:1.14.9
    - workflow-job:2.32
    - workflow-aggregator:2.6
    - credentials-binding:1.18
    - git:3.9.3
    - blueocean:1.14.0
    - dashboard-view:2.10
    - build-name-setter:1.7.1
    - config-file-provider:3.6
    - embeddable-build-status:2.0.1
    - rebuild:1.30
    - ssh-agent:1.17
    - throttle-concurrents:2.0.1
    - nodejs:1.2.9
    - checkstyle:4.0.0
    - cobertura:1.13
    - htmlpublisher:1.18
    - junit:1.27
    - warnings-ng:4.0.0
    - xunit:2.3.3
    - build-pipeline-plugin:1.5.8
    - conditional-buildstep:1.3.6
    - jenkins-multijob-plugin:1.32
    - parameterized-trigger:2.35.2
    - copyartifact:1.42
    - git-parameter:0.9.10
    - github:1.29.4
    - matrix-project:1.14
    - role-strategy:2.10
    - active-directory:2.13
    - emailext-template:1.1
    - publish-over-ssh:1.20.1
    - ssh:2.6.1
    - periodicbackup:1.5
    - thinBackup:1.9
    - jobConfigHistory:2.20
    - simple-theme-plugin:0.5.1
    - cucumber-testresult-plugin:0.10.1
    - jacoco:3.0.4
    - nodelabelparameter:1.7.2
    - jenkinswalldisplay:0.6.34
    - golang:1.2
    - audit-trail:2.4
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
  - host: a40e469bc910911e992f2023646f1c56-1142892619.us-east-1.elb.amazonaws.com
    http:
      paths:
      - backend:
          serviceName: kiali
          servicePort: 20001
        path: /kiali
EOF

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
  - host: a40e469bc910911e992f2023646f1c56-1142892619.us-east-1.elb.amazonaws.com
    http:
      paths:
      - backend:
          serviceName: tracing
          servicePort: 80
        path: /jaeger
EOF

kubectl create -f ~/jaeger-ingress.yaml

#### Install Zipkin Ingress
cat > ~/zipkin-ingress.yaml <<EOF

EOF