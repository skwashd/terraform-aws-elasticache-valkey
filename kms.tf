resource "aws_kms_key" "cache" {
  description             = "Encrypts the ${var.name} Valkey replication group at rest."
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.name}-valkey-cache"
  })
}

resource "aws_kms_alias" "cache" {
  name          = "alias/${var.name}-valkey-cache"
  target_key_id = aws_kms_key.cache.key_id
}

resource "aws_kms_key" "secrets" {
  description             = "Encrypts the ${var.name} Valkey Secrets Manager secrets."
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.name}-valkey-secrets"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.name}-valkey-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "KeyAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = local.kms_admin_arns
    }
  }

  statement {
    sid = "DelegateCryptoToIam"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:List*",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.account_root_arn]
    }
  }

  statement {
    sid = "DelegateGrantsToIam"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.account_root_arn]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key_policy" "cache" {
  key_id = aws_kms_key.cache.id
  policy = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_key_policy" "secrets" {
  key_id = aws_kms_key.secrets.id
  policy = data.aws_iam_policy_document.kms.json
}
