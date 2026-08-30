resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.trendstore.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_node_group.trendstore]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.trendstore.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.trendstore]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.trendstore.name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_node_group.trendstore]
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.trendstore.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.trendstore.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "trendstore-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.trendstore.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  depends_on               = [aws_eks_node_group.trendstore]
}
