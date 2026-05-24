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
