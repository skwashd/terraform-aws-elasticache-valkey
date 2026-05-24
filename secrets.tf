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
