resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.name}-valkey"
  description = "Subnets for the ${var.name} Valkey replication group."
  subnet_ids  = var.subnet_ids

  tags = var.tags
}

resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.name}-valkey"
  family      = local.parameter_group_family
  description = "Parameters for the ${var.name} Valkey replication group."

  dynamic "parameter" {
    for_each = var.parameter_group_parameters

    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = var.tags
}

resource "random_integer" "maintenance_hour" {
  min = 0
  max = 3
}

resource "random_integer" "maintenance_minute" {
  min = 0
  max = 59
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name}-valkey"
  description          = "${var.name} Valkey replication group."

  engine                     = "valkey"
  engine_version             = var.engine_version
  auto_minor_version_upgrade = true
  node_type                  = local.node_type
  port                       = local.port

  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.this.id]
  user_group_ids       = [aws_elasticache_user_group.this.user_group_id]

  num_cache_clusters         = var.num_replicas + 1
  automatic_failover_enabled = var.num_replicas > 0
  multi_az_enabled           = var.num_replicas > 0

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = aws_kms_key.cache.arn

  apply_immediately        = true
  maintenance_window       = local.maintenance_window
  snapshot_retention_limit = 7

  tags = var.tags
}
