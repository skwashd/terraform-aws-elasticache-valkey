provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "valkey" {
  source = "../.."

  name       = "example"
  size       = "small"
  subnet_ids = slice(data.aws_subnets.default.ids, 0, 2)

  tags = {
    environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_app" {
  security_group_id = module.valkey.security_group_id

  description = "Allow app servers to reach the Valkey cluster."
  ip_protocol = "tcp"
  from_port   = module.valkey.port
  to_port     = module.valkey.port
  cidr_ipv4   = data.aws_vpc.default.cidr_block

  tags = {
    environment = "dev"
    Name        = "example-valkey-from-app"
  }
}
