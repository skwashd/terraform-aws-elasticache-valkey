# Terraform Module for AWS Elasticache Valkey Cluster

Opinionated Terraform module for an AWS ElastiCache **Valkey** replication group. Drops into a stack with minimal wiring and ships with everything the cluster needs to run: subnet group, parameter group, security group, two RBAC users (`admin` and `standard`) with credentials stored in Secrets Manager, and customer-managed KMS keys for at-rest and secret encryption.

## Features

- **Always-on encryption** — at-rest (customer-managed KMS) and in-transit. Required because RBAC users on Valkey only work with TLS.
- **RBAC users out of the box** — `admin` (full access) and `standard` (everything except admin and dangerous commands). A disabled `default` user is also present because AWS requires it in every user group. Credentials for the two enabled users live in Secrets Manager and are encrypted with a dedicated CMK.
- **T-shirt instance sizing** — `xsmall` through `xlarge` maps to a sensible node type.
- **Randomised maintenance window** — 2-hour window on Sunday morning UTC, picked at first apply and stable thereafter.
- **Caller-owned ingress** — the module creates the security group and the minimum self-referencing rules the cluster needs for intra-cluster traffic, then outputs the SG ID so you wire your own ingress.

## Hardcoded defaults

The module deliberately does not expose the following as variables:

- `apply_immediately = true`
- `snapshot_retention_limit = 7`
- Secrets Manager `recovery_window_in_days = 7`
- KMS `deletion_window_in_days = 7`, `enable_key_rotation = true`
- `auto_minor_version_upgrade = true`
- `transit_encryption_enabled = true`, `at_rest_encryption_enabled = true`

The Valkey engine version is configured via the `engine_version` input — note the name: `version` would conflict with a Terraform-reserved variable name.

## Usage

```hcl
module "valkey" {
  source = "github.com/your-org/terraform-aws-elasticache-valkey"

  name       = "myapp-prod"
  size       = "medium"
  subnet_ids = ["subnet-52b922b455547adca", "subnet-87e995833832d89b6"]

  tags = {
    environment = "prod"
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_app" {
  security_group_id = module.valkey.security_group_id

  description = "Allow app servers to reach the cache."
  ip_protocol = "tcp"
  from_port   = module.valkey.port
  to_port     = module.valkey.port

  referenced_security_group_id = aws_security_group.app.id

  tags = {
    environment = "prod"
  }
}
```

See `examples/basic/` for a complete runnable example.

## Sizing

| `size`   | Node type        |
|----------|------------------|
| `xsmall` | `cache.t4g.micro`|
| `small`  | `cache.t4g.small`|
| `medium` | `cache.t4g.medium`|
| `large`  | `cache.m7g.large`|
| `xlarge` | `cache.m7g.xlarge`|

## Replicas and availability

- `num_replicas = 0` (default) gives a single-node replication group: no read replicas, no automatic failover, no Multi-AZ. Cheapest, lowest availability.
- `num_replicas >= 1` enables automatic failover and Multi-AZ. Reader endpoint is then non-empty and round-robins across the replicas.

## Secrets

Two Secrets Manager secrets are created, each encrypted with the module-managed CMK. The payload is JSON:

```json
{
  "username": "...",
  "password": "...",
  "endpoint": "...",
  "port": 6379
}
```

Pull them by ARN:
- `admin_user_secret_arn` — full admin access (`+@all`).
- `user_secret_arn` — standard user access (`+@all -@admin -@dangerous`).

### State-hardening with write-only attributes

User passwords and Secrets Manager payloads are managed through Terraform's **write-only** attributes, so the cleartext password and secret payload don't appear in state on the cluster user or secret-version resources — anyone reading the state file gets `null` for those fields.

This requires Terraform `>= 1.11.0`. The password still lives in module state on the `random_password` resources, so write-only narrows the exposure surface rather than eliminating it.

### Rotating credentials

`passwords_wo_version` and `secret_string_wo_version` are hardcoded to `1` in the module — the module does not auto-rotate. To force a rotation:

1. Taint the random password(s) you want to rotate: `terraform taint module.valkey.random_password.admin` (and `.standard` if you want both).
2. Bump `passwords_wo_version` (in `users.tf`) and `secret_string_wo_version` (in `secrets.tf`) from `1` to `2` for the affected user(s) and secret(s).
3. `terraform apply`.

The bump is what tells Terraform to push the freshly-regenerated password through write-only — without it the new value sits in `random_password` state but never reaches ElastiCache or Secrets Manager.

## Maintenance window

Maintenance is pinned to **Sunday** with a 2-hour window. The start time is randomised at first apply (somewhere in the **00:00–03:59 UTC** range) and stays put for the life of the module.

## Validation

The repo ships a `.tflint.hcl` and `scripts/validate.sh` from the `terraform-review` skill. To validate locally:

```sh
terraform init    # one-time; required so terraform validate has providers available
scripts/validate.sh
```

The script runs `terraform fmt -recursive -check -diff`, `terraform validate`, `tflint --init`, and `tflint --recursive`. Extra arguments are passed through to `tflint`.

# Generated Docs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0, < 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.45.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_elasticache_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_replication_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_elasticache_user.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_user) | resource |
| [aws_elasticache_user.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_user) | resource |
| [aws_elasticache_user.standard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_user) | resource |
| [aws_elasticache_user_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_user_group) | resource |
| [aws_kms_alias.cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.standard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.standard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.cluster_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.cluster_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [random_integer.maintenance_hour](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [random_integer.maintenance_minute](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [random_password.admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.default](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.standard](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_subnet.first](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Valkey engine version, in MAJOR.MINOR format. The major component is used to derive the parameter group family (e.g. "9.0" -> "valkey9"). Minor versions upgrade automatically. | `string` | `"9.0"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix applied to every resource the module creates. Must be lowercase kebab-case and short enough to fit within ElastiCache and Secrets Manager name limits (<= 32 chars). Used verbatim, so pick something like "<app>-<env>". | `string` | n/a | yes |
| <a name="input_num_replicas"></a> [num\_replicas](#input\_num\_replicas) | Number of read replicas to provision behind the primary. 0 means single-node, no HA. Setting > 0 enables Multi-AZ and automatic failover. | `number` | `0` | no |
| <a name="input_parameter_group_parameters"></a> [parameter\_group\_parameters](#input\_parameter\_group\_parameters) | Map of Valkey parameters to override on the module-managed parameter group. Use this for tuning eviction policy, keyspace notifications, etc. Keys/values map directly to ElastiCache parameter names and values. | `map(string)` | `{}` | no |
| <a name="input_size"></a> [size](#input\_size) | T-shirt size that selects the node instance type. xsmall: cache.t4g.micro, small: cache.t4g.small, medium: cache.t4g.medium, large: cache.m7g.large, xlarge: cache.m7g.xlarge. | `string` | `"small"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets the ElastiCache subnet group covers. Must all live in the same VPC. The VPC is derived from the first subnet, so all subnets must be in that VPC. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every taggable resource the module creates. Must include an "environment" key. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_admin_user_secret_arn"></a> [admin\_user\_secret\_arn](#output\_admin\_user\_secret\_arn) | ARN of the Secrets Manager secret holding the admin user's credentials. |
| <a name="output_cache_kms_key_arn"></a> [cache\_kms\_key\_arn](#output\_cache\_kms\_key\_arn) | ARN of the customer-managed KMS key encrypting the replication group at rest. |
| <a name="output_port"></a> [port](#output\_port) | TCP port the Valkey cluster listens on. |
| <a name="output_primary_endpoint_address"></a> [primary\_endpoint\_address](#output\_primary\_endpoint\_address) | Address of the primary node. Use this for writes and (when num\_replicas == 0) all traffic. |
| <a name="output_reader_endpoint_address"></a> [reader\_endpoint\_address](#output\_reader\_endpoint\_address) | Reader endpoint that load-balances across read replicas. Empty string when num\_replicas == 0. |
| <a name="output_replication_group_id"></a> [replication\_group\_id](#output\_replication\_group\_id) | Identifier of the ElastiCache replication group. |
| <a name="output_secrets_kms_key_arn"></a> [secrets\_kms\_key\_arn](#output\_secrets\_kms\_key\_arn) | ARN of the customer-managed KMS key encrypting the Secrets Manager secrets. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group attached to the cluster. Attach your own ingress rules to this SG to grant access. |
| <a name="output_user_group_id"></a> [user\_group\_id](#output\_user\_group\_id) | Identifier of the ElastiCache RBAC user group attached to the replication group. |
| <a name="output_user_secret_arn"></a> [user\_secret\_arn](#output\_user\_secret\_arn) | ARN of the Secrets Manager secret holding the standard (non-admin) user's credentials. |
<!-- END_TF_DOCS -->