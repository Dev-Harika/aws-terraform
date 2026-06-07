# Reusable IAM role with optional IRSA (Kubernetes service account) trust

locals {
  irsa_trust = var.irsa_namespace != null && var.oidc_provider_arn != null
}

data "aws_iam_policy_document" "assume" {
  # Standard AWS service trust
  dynamic "statement" {
    for_each = length(var.trusted_services) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "Service"
        identifiers = var.trusted_services
      }
    }
  }

  # IRSA — Kubernetes pods via OIDC
  dynamic "statement" {
    for_each = local.irsa_trust ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals {
        type        = "Federated"
        identifiers = [var.oidc_provider_arn]
      }
      condition {
        test     = "StringEquals"
        variable = "${replace(var.oidc_provider_arn, "/^.*provider//", "")}:sub"
        values   = ["system:serviceaccount:${var.irsa_namespace}:${var.irsa_service_account}"]
      }
      condition {
        test     = "StringEquals"
        variable = "${replace(var.oidc_provider_arn, "/^.*provider//", "")}:aud"
        values   = ["sts.amazonaws.com"]
      }
    }
  }

  # Cross-account trust
  dynamic "statement" {
    for_each = length(var.trusted_role_arns) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = var.trusted_role_arns
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Inline custom policy (optional)
resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json != null ? 1 : 0

  name   = "${var.name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
