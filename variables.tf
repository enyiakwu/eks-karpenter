
variable "public_subnets" {
  description = "List of subnet IDs"
  type        = list(string)
  default       = ["subnet-d1addab8", "subnet-e56bada9", "subnet-2f962555"]
}


# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
# }

# variable "cluster_role_arn" {
#   description = "ARN of the IAM role for the EKS cluster"
#   type        = string
# }



# variable "kubernetes_version" {
#   description = "Kubernetes version for the EKS cluster"
#   type        = string
# }

# variable "node_group_name" {
#   description = "Name of the node group"
#   type        = string
# }

# variable "node_role_arn" {
#   description = "ARN of the IAM role for the node group"
#   type        = string
# }

# variable "desired_size" {
#   description = "Desired number of nodes"
#   type        = number
# }

# variable "max_size" {
#   description = "Maximum number of nodes"
#   type        = number
# }

# variable "min_size" {
#   description = "Minimum number of nodes"
#   type        = number
# }

# variable "instance_types" {
#   description = "List of instance types for the node group"
#   type        = list(string)
# }

# variable "cluster_policy_attachment" {
#   type        = any
#   }


# IAM Variables

# variable "cluster_role_name" {
#   description = "Name of the IAM role for the EKS cluster"
#   type        = string
# }

# variable "node_role_name" {
#   description = "Name of the IAM role for the node group"
#   type        = string
# }

# variable "eks_module" {
#   type = any
# }


# variable "cluster_endpoint" {
#   description = "Endpoint of the EKS cluster"
#   type        = string
# }

# variable "cluster_ca" {
#   description = "Certificate authority of the EKS cluster"
#   type        = string
# }






