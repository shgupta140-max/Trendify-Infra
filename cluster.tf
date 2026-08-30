resource "aws_eks_cluster" "trendstore" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_cluster_version

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids             = [aws_subnet.public_01.id, aws_subnet.public_02.id]
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = {
    Name = "trendstore-cluster"
  }
}

resource "aws_eks_node_group" "trendstore" {
  cluster_name    = aws_eks_cluster.trendstore.name
  node_group_name = "trendstore-ng"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = [aws_subnet.public_01.id, aws_subnet.public_02.id]

  capacity_type  = var.eks_node_capacity_type
  instance_types = [var.eks_node_instance_type]

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_readonly,
  ]

  tags = {
    Name = "trendstore-nodegroup"
  }
}

resource "aws_eks_access_entry" "cluster_admin" {
  for_each = toset(var.cluster_admin_principals)

  cluster_name      = aws_eks_cluster.trendstore.name
  principal_arn     = each.value
  kubernetes_groups = ["system:masters"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  for_each = aws_eks_access_entry.cluster_admin

  cluster_name  = aws_eks_cluster.trendstore.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}
