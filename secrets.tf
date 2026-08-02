resource "random_password" "default" {
  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "random_password" "admin" {
  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "random_password" "standard" {
  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "aws_secretsmanager_secret" "admin" {
  name                    = "${var.name}-valkey-admin"
  description             = "Admin user credentials for the ${var.name} Valkey cluster."
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "admin" {
  secret_id = aws_secretsmanager_secret.admin.id

  secret_string_wo = jsonencode({
    username = aws_elasticache_user.admin.user_name
    password = random_password.admin.result
    endpoint = aws_elasticache_replication_group.this.primary_endpoint_address
    port     = aws_elasticache_replication_group.this.port
  })

  secret_string_wo_version = 1
}

data "aws_iam_policy_document" "admin_secret" {
  statement {
    sid = "AllowWrite"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = local.admin_secret_writer_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.admin_secret_access.readers) > 0 ? [1] : []

    content {
      sid = "AllowRead"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.admin_secret_access.readers
      }
    }
  }

  statement {
    sid       = "DenyOtherReads"
    effect    = "Deny"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.admin_secret_reader_exemptions
    }
  }
}

resource "aws_secretsmanager_secret_policy" "admin" {
  secret_arn = aws_secretsmanager_secret.admin.arn
  policy     = data.aws_iam_policy_document.admin_secret.json
}

resource "aws_secretsmanager_secret" "standard" {
  name                    = "${var.name}-valkey-standard"
  description             = "Standard user credentials for the ${var.name} Valkey cluster."
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "standard" {
  secret_id = aws_secretsmanager_secret.standard.id

  secret_string_wo = jsonencode({
    username = aws_elasticache_user.standard.user_name
    password = random_password.standard.result
    endpoint = aws_elasticache_replication_group.this.primary_endpoint_address
    port     = aws_elasticache_replication_group.this.port
  })

  secret_string_wo_version = 1
}

data "aws_iam_policy_document" "standard_secret" {
  statement {
    sid = "AllowWrite"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = local.standard_secret_writer_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.standard_secret_access.readers) > 0 ? [1] : []

    content {
      sid = "AllowRead"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.standard_secret_access.readers
      }
    }
  }

  statement {
    sid       = "DenyOtherReads"
    effect    = "Deny"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.standard_secret_reader_exemptions
    }
  }
}

resource "aws_secretsmanager_secret_policy" "standard" {
  secret_arn = aws_secretsmanager_secret.standard.arn
  policy     = data.aws_iam_policy_document.standard_secret.json
}
