# 1. Look up the cluster and OIDC details dynamically using your variable
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# 2. Fetch the official AWS Load Balancer Controller IAM policy
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.10.0/docs/install/iam_policy.json"
}

# 3. Create the IAM Policy
resource "aws_iam_policy" "lbc_iam_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.lbc_iam_policy.response_body
}

# 4. Create the Trust Policy for IRSA
data "aws_iam_policy_document" "lbc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.oidc.arn]
      type        = "Federated"
    }
  }
}

# 5. Create the IAM Role and Attach the Policy
resource "aws_iam_role" "lbc_iam_role" {
  name               = "AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lbc_iam_role_attachment" {
  role       = aws_iam_role.lbc_iam_role.name
  policy_arn = aws_iam_policy.lbc_iam_policy.arn
}

# 6. Deploy the Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.0"

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lbc_iam_role.arn
  }

  set {
    name  = "vpcId"
    value = aws_vpc.trendstore.id
  }
  depends_on = [
    aws_iam_role_policy_attachment.lbc_iam_role_attachment
  ]
}