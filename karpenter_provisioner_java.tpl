apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: java
spec:
  labels:
    workload-type/java: "true"
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
    - m5.large
    - m5.xlarge
    - m5.2xlarge
    - m5.4xlarge
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
    key: workload-type/java
    value: "true"
  ttlSecondsAfterEmpty: 30
  ttlSecondsUntilExpired: 172800