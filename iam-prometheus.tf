data "aws_iam_policy_document" "prometheus" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:monitoring:prometheus"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "prometheus" {
  assume_role_policy = data.aws_iam_policy_document.prometheus.json
  name               = "prometheus-role"
}

resource "aws_iam_policy" "prometheus_ingest_access" {
  name = "PrometheusIngestAccess"

  policy = jsonencode({
    Statement = [{
      Action = [
        "aps:RemoteWrite"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_ingest_access" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_ingest_access.arn
}


