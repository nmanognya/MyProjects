output "role_arn" {
  description = "IAM role assumed by the Kubernetes workload through EKS Pod Identity."
  value       = aws_iam_role.this.arn
}

output "association_id" {
  description = "EKS Pod Identity association identifier."
  value       = aws_eks_pod_identity_association.this.association_id
}

output "association_arn" {
  description = "EKS Pod Identity association ARN."
  value       = aws_eks_pod_identity_association.this.association_arn
}
