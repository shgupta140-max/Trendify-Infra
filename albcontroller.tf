# 1. Fetch the TLS certificate for the OIDC issuer
data "tls_certificate" "eks" {
  url = aws_eks_cluster.trendstore.identity[0].oidc[0].issuer
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
      variable = "${replace(aws_eks_cluster.trendstore.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.trendstore.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      # This now references the RESOURCE created in step 2, not a data block
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
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
# 7. Deploy the Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.0"

  # Use yamlencode to bypass Helm's problematic dot parser
  values = [
    yamlencode({
      clusterName = aws_eks_cluster.trendstore.name
      vpcId       = aws_vpc.trendstore.id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.lbc_iam_role.arn
        }
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.lbc_iam_role_attachment
  ]
}