output "cluster_name" {
  value = module.eks.cluster_name
}

output "node_group_name" {
  value = module.eks.node_groups["karpenter"].name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  value = module.eks.cluster_certificate_authority
}

output "worker_iam_role_name" {
  value = module.eks.worker_iam_role_name
}

output "karpenter_release" {
  value = helm_release.karpenter.id
}




# output "cluster_name" {
#   value = module.eks.cluster_id
# }

# output "node_group_name" {
#   value = aws_eks_node_group.this.node_group_name
# }

# output "cluster_endpoint" {
#   value = module.eks.cluster_endpoint
# }

# output "cluster_certificate_authority" {
#   value = module.eks.cluster_certificate_authority_data # aws_eks_cluster.this.certificate_authority.0.data
# }

# output "worker_iam_role_name" {
#   value = module.eks.worker_iam_role_name
# }

# # EKS cluster output

# # output "cluster_name" {
# #   value = aws_eks_cluster.this.name
# # }

# # output "cluster_endpoint" {
# #   value = aws_eks_cluster.this.endpoint
# # }

# # output "cluster_certificate_authority" {
# #   value = aws_eks_cluster.this.certificate_authority[0].data
# # }

# # output "worker_iam_role_name" {
# #   value = aws_iam_role.worker_iam_role.name
# # }



# # IAM outputs

# # output "cluster_role_arn" {
# #   value = module.eks_cluster_role.arn
# # }

# # output "node_role_arn" {
# #   value = aws_iam_role.eks_node_role.arn
# # }

# # output "cluster_policy_attachment" {
# #   value = aws_iam_role_policy_attachment.eks_cluster_policy_attachment
# # }

# # output "karpenter_release" {
# #   value = helm_release.karpenter.id
# # }





