output "admin_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the admin user's credentials."
  value       = aws_secretsmanager_secret.admin.arn
}

output "cache_kms_key_arn" {
  description = "ARN of the customer-managed KMS key encrypting the replication group at rest."
  value       = aws_kms_key.cache.arn
}

output "port" {
  description = "TCP port the Valkey cluster listens on."
  value       = aws_elasticache_replication_group.this.port
}

output "primary_endpoint_address" {
  description = "Address of the primary node. Use this for writes and (when num_replicas == 0) all traffic."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint that load-balances across read replicas. Empty string when num_replicas == 0."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "replication_group_id" {
  description = "Identifier of the ElastiCache replication group."
  value       = aws_elasticache_replication_group.this.id
}

output "security_group_id" {
  description = "ID of the security group attached to the cluster. Attach your own ingress rules to this SG to grant access."
  value       = aws_security_group.this.id
}

output "secrets_kms_key_arn" {
  description = "ARN of the customer-managed KMS key encrypting the Secrets Manager secrets."
  value       = aws_kms_key.secrets.arn
}

output "user_group_id" {
  description = "Identifier of the ElastiCache RBAC user group attached to the replication group."
  value       = aws_elasticache_user_group.this.user_group_id
}

output "user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the standard (non-admin) user's credentials."
  value       = aws_secretsmanager_secret.standard.arn
}
