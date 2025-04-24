resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  namespace        = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.0.1"
  create_namespace = true

  values = [
    <<-EOT
controller:
  replicaCount: 2
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-internal: "false"  # Set to "true" for internal load balancer
  externalTrafficPolicy: Local
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
EOT
  ]

  depends_on = [helm_release.aws_lb_controller]
}


resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [<<EOF
region: us-east-1
clusterName: ${aws_eks_cluster.cluster.name}
vpcId: ${aws_vpc.main.id}
serviceAccount:
  create: true
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.aws_lb_controller_role.arn}

EOF
  ]
}


resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [helm_release.nginx_ingress]
}


resource "kubectl_manifest" "letsencrypt_issuer" {
  provider   = kubectl
  yaml_body  = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        email: "markibaevadilet2@gmail.com"
        server: "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
        - http01:
            ingress:
              class: nginx
  YAML
  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "tls_certificate" {
  provider   = kubectl
  yaml_body  = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: cert-tls
      namespace: nginx-ingress
    spec:
      secretName: cert-tls
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      commonName: 637423169013.realhandsonlabs.net 
      dnsNames:
      - 637423169013.realhandsonlabs.net
  YAML
  depends_on = [kubectl_manifest.letsencrypt_issuer]
}
