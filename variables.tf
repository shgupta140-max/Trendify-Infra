variable "aws_region" {
  description = "AWS region where the TrendStore infrastructure will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the TrendStore VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_01_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_02_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "trendstore-cluster"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.36"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type used for the EKS managed node group. t3.small is a safer default than t3.micro for EKS bootstrap and node health."
  type        = string
  default     = "t2.medium"
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_capacity_type" {
  description = "Capacity type for the EKS managed node group. On-demand is used for faster provisioning and predictable startup."
  type        = string
  default     = "ON_DEMAND"
}

variable "cluster_admin_principals" {
  description = "List of IAM principal ARNs that should be granted cluster admin access to the EKS cluster and AWS EKS Console"
  type        = list(string)
  default     = ["arn:aws:iam::409415529933:user/terraform-user", "arn:aws:iam::409415529933:root"]
}

variable "jenkins_admin_principal_arn" {
  description = "IAM principal ARN for Jenkins admin access to the EKS cluster"
  type        = string
  default     = "arn:aws:iam::409415529933:role/Jenkins-EC2-Profile"
}
