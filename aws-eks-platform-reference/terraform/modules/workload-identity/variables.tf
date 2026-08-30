variable "cluster_name" {
  description = "EKS cluster name that owns the Pod Identity association."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace containing the workload ServiceAccount."
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount that receives temporary AWS credentials."
  type        = string
}

variable "cloudwatch_namespace" {
  description = "Only CloudWatch custom-metric namespace this workload may publish to."
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM and EKS resources."
  type        = map(string)
  default     = {}
}
