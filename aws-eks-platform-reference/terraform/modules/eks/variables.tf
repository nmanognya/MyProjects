variable "name" {
  description = "EKS cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version."
  type        = string
  default     = "1.33"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the cluster and managed node group."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnets are required for a multi-AZ EKS deployment."
  }
}

variable "enable_public_endpoint" {
  description = "Whether the Kubernetes API server exposes a public endpoint."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs permitted to reach the public API endpoint when enabled."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "EC2 instance types allowed for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Managed node group capacity type: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "desired_size" {
  description = "Desired managed node count."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum managed node count."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum managed node count."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags applied to EKS and IAM resources."
  type        = map(string)
  default     = {}
}
