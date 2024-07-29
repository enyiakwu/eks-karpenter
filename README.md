# EKS Cluster with Karpenter

This Terraform configuration deploys an EKS cluster with Karpenter, supporting both x86 and arm64 instances, into an existing VPC. The VPC has to be already existing and the details is currently on the locals block of the main.tf of the configuration. This can be moved to a variable defaults value or entered on the command line during CLI runtime.

## Prerequisites

- Terraform installed
- AWS CLI configured
- kubectl installed
- Helm installed
- Existing VPC and AWS S3 bucket for S3 bucket backend

## Usage
**Note: To use your own existing AWS account and credentials, run the following key configuration:**
```
export AWS_ACCESS_KEY_ID=AKXXXXXXXXXXXXXXXU
export AWS_SECRET_ACCESS_KEY=xxxxxxxXXXXXXXxxxxxxxxXXXX/XXXXX
```

1. **Clone the repository**

   ```sh
   git clone https://github.com/enyiakwu/eks-karpenter.git
   cd eks-karpenter

2. **Initialize Terraform**
   
   ```sh
   Copy code
   terraform init

3. **Plan for the Terraform deployment**
   
   ```sh
   terraform plan -var 'public_subnets= ["subnet-d1addab8", "subnet-e56bada9", "subnet-2f962555"]' -out=outfile.plan 

4. **Apply the Terraform configuration**
   
   ```sh
   terraform apply -var 'public_subnets= ["subnet-d1addab8", "subnet-e56bada9", "subnet-2f962555"]'

5. **Configure kubectl**
   
   ```sh
   aws eks --region eu-west-1 update-kubeconfig --name $(terraform output -raw cluster_name)

6. **Verify Karpenter installation**
   
   ```sh
   kubectl get pods -n karpenter
