# Karpenter EKS Terraform Deployment

This project provides a complete infrastructure-as-code solution for deploying an AWS EKS (Elastic Kubernetes Service) cluster with Karpenter for dynamic node provisioning, along with supporting components such as NGINX Ingress, Prometheus, and IAM roles, using Terraform.

## Features

- **VPC and Networking**: Provisions a secure VPC with public and private subnets, NAT gateways, and routing for the EKS cluster.
- **EKS Cluster**: Deploys a production-ready EKS cluster with managed node groups.
- **IAM Roles**: Sets up all necessary IAM roles and policies for EKS, Karpenter, and supporting services.
- **Karpenter**: Installs Karpenter via Helm and configures provisioners for different workloads (e.g., Golang, Java) using templated YAML.
- **Ingress and Monitoring**: Deploys NGINX Ingress Controller and Prometheus for monitoring.
- **Modular and Extensible**: Uses Terraform modules and templating for easy customization.

## How It Works

1. **VPC Setup**:  
   The `vpc.tf` file provisions a VPC, public/private subnets, route tables, internet/NAT gateways, and associates them for EKS networking.

2. **EKS Cluster**:  
   The `eks.tf` file creates the EKS cluster, security groups, and node groups using the AWS provider.

3. **IAM Configuration**:  
   The `iam.tf` and related files set up IAM roles and policies for the EKS cluster, nodes, and Karpenter, including OIDC integration for Kubernetes service accounts.

4. **Karpenter Installation**:  
   - The `karpenter.tf` file:
     - Creates a Kubernetes namespace for Karpenter.
     - Sets up IAM roles for Karpenter with OIDC.
     - Installs Karpenter using the Helm provider.
     - Generates Karpenter provisioner manifests for different workloads (Golang, Java) using Terraform templates.
     - Applies these manifests to the cluster using the `kubectl_manifest` resource.

5. **Ingress and Monitoring**:  
   - The `nginx.tf` file deploys the NGINX Ingress Controller and AWS Load Balancer Controller.
   - The `prometheus.tf` file deploys Prometheus for monitoring.

6. **Provisioners**:  
   - Provisioner YAMLs (e.g., `karpenter_provisioner_golang.yaml`) define how Karpenter should provision nodes for specific workloads, including instance types, taints, and resource limits.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 0.13
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for interacting with the cluster
- [Helm](https://helm.sh/) (optional, for manual chart management)
- AWS account with permissions to create EKS, VPC, IAM, and related resources

## Usage

1. **Clone the repository**
   ```sh
   git clone https://github.com/adilet18/karpenter.git
   cd karpenter
   ```

2. **Configure AWS Credentials**
   Make sure your AWS CLI is configured:
   ```sh
   aws configure
   ```

3. **Initialize Terraform**
   ```sh
   terraform init
   ```

4. **Review and Customize Variables**
   - Edit `variables.tf` to adjust VPC, cluster, and node group settings as needed.
   - Edit provisioner templates (`karpenter_provisioner_golang.tpl`, etc.) if you need custom node provisioning logic.

5. **Plan the Deployment**
   ```sh
   terraform plan
   ```

6. **Apply the Deployment**
   ```sh
   terraform apply
   ```

7. **Access Your Cluster**
   - Update your kubeconfig:
     ```sh
     aws eks update-kubeconfig --region us-east-1 --name <your-cluster-name>
     ```
   - Verify nodes and workloads:
     ```sh
     kubectl get nodes
     kubectl get pods -A
     ```

## File Structure

- `vpc.tf` - VPC and networking resources
- `eks.tf` - EKS cluster and node groups
- `iam.tf`, `iam-*.tf` - IAM roles and policies
- `karpenter.tf` - Karpenter installation and provisioner management
- `nginx.tf` - NGINX Ingress and AWS Load Balancer Controller
- `prometheus.tf` - Prometheus monitoring
- `variables.tf` - Input variables
- `outputs.tf` - Terraform outputs
- `karpenter_provisioner_*.tpl` - Provisioner templates for Karpenter
- `karpenter_provisioner_*.yaml` - Generated provisioner manifests

## Customization

- **Provisioners**: Add or modify provisioner templates to support different workloads or instance types.
- **Monitoring/Ingress**: Adjust Helm values in `nginx.tf` and `prometheus.tf` as needed.
- **Scaling**: Tune node group and Karpenter provisioner settings for your workload requirements.

## Cleanup

To destroy all resources created by this project:
```sh
terraform destroy
```

---

## Troubleshooting

- Ensure your AWS credentials are valid and have sufficient permissions.
- If you encounter issues with Karpenter or Helm releases, check the Kubernetes and Helm provider versions.
- For ECR or Docker issues, ensure you are using the correct AWS CLI login command and your credentials are active.

---

## License

MIT or your preferred license.
