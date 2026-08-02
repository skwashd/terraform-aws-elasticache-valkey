resource "aws_security_group" "this" {
  name        = "${var.name}-valkey"
  description = "Controls network access to the ${var.name} Valkey cluster."
  vpc_id      = local.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-valkey"
  })
}

resource "aws_vpc_security_group_ingress_rule" "cluster_self" {
  security_group_id = aws_security_group.this.id

  description                  = "Intra-cluster replication and gossip on the Valkey port."
  ip_protocol                  = "tcp"
  from_port                    = local.port
  to_port                      = local.port
  referenced_security_group_id = aws_security_group.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-valkey-cluster-self-ingress"
  })
}

resource "aws_vpc_security_group_egress_rule" "cluster_self" {
  security_group_id = aws_security_group.this.id

  description                  = "Intra-cluster replication and gossip on the Valkey port."
  ip_protocol                  = "tcp"
  from_port                    = local.port
  to_port                      = local.port
  referenced_security_group_id = aws_security_group.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-valkey-cluster-self-egress"
  })
}
