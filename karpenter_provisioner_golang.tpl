apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: golang
spec:
  labels:
    workload-type/golang: "true"
  limits:
    resources:
      cpu: 1k
      memory: 1000Gi
  provider:
    apiVersion: extensions.karpenter.sh/v1alpha1
    kind: AWS
    securityGroupSelector:
      karpenter.sh/discovery/${cluster_name}-node: ${cluster_name}
    subnetSelector:
      karpenter.sh/discovery: ${cluster_name}
  requirements:
  - key: node.kubernetes.io/instance-type
    operator: In
    values:
    - c5.2xlarge
    - c5.large
    - c5.xlarge
  - key: karpenter.sh/capacity-type
    operator: In
    values:
    - on-demand
  - key: kubernetes.io/arch
    operator: In
    values:
    - amd64
  taints:
  - effect: NoSchedule
    key: workload-type/golang
    value: "true"
  ttlSecondsAfterEmpty: 30
  ttlSecondsUntilExpired: 172800