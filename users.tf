resource "aws_elasticache_user" "default" {
  user_id              = "${var.name}-valkey-default"
  user_name            = "default"
  engine               = "valkey"
  access_string        = "off resetchannels -@all"
  passwords_wo         = random_password.default.result
  passwords_wo_version = 1

  tags = var.tags
}

resource "aws_elasticache_user" "admin" {
  user_id              = "${var.name}-valkey-admin"
  user_name            = "admin"
  engine               = "valkey"
  access_string        = "on ~* &* +@all"
  passwords_wo         = random_password.admin.result
  passwords_wo_version = 1

  tags = var.tags
}

resource "aws_elasticache_user" "standard" {
  user_id              = "${var.name}-valkey-standard"
  user_name            = "standard"
  engine               = "valkey"
  access_string        = "on ~* &* +@all -@admin -@dangerous"
  passwords_wo         = random_password.standard.result
  passwords_wo_version = 1

  tags = var.tags
}

resource "aws_elasticache_user_group" "this" {
  user_group_id = "${var.name}-valkey"
  engine        = "valkey"

  user_ids = [
    aws_elasticache_user.default.user_id,
    aws_elasticache_user.admin.user_id,
    aws_elasticache_user.standard.user_id,
  ]

  tags = var.tags
}
