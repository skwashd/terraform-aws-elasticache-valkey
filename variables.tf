variable "admin_secret_access" {
  description = "Access control for the admin-credentials secret (full +@all access). readers: IAM role/user ARNs (aws:PrincipalArn form -- NOT assumed-role session ARNs) allowed to GetSecretValue; every other principal is denied, and readers must also hold kms:Decrypt on the secrets CMK (see secrets_kms_key_arn output). writers: additional ARNs allowed to PutSecretValue/UpdateSecret (the deploy caller is always a writer). Default {} means only the deploy caller can read or write this secret."
  type = object({
    readers = optional(list(string), [])
    writers = optional(list(string), [])
  })
  default = {}
}

variable "engine_version" {
  description = "Valkey engine version, in MAJOR.MINOR format. The major component is used to derive the parameter group family (e.g. \"9.0\" -> \"valkey9\"). Minor versions upgrade automatically."
  type        = string
  default     = "9.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.engine_version))
    error_message = "engine_version must be in MAJOR.MINOR format, e.g. \"9.0\"."
  }
}

variable "kms_admin_arns" {
  description = "Additional IAM role or user ARNs granted full administrative (kms:*) access to the module's KMS keys, on top of the current caller (always an administrator). Cryptographic use is delegated to IAM separately. ARNs must be existing principals. Empty (default) makes the caller the sole key administrator."
  type        = list(string)
  default     = []
}

variable "name" {
  description = "Name prefix applied to every resource the module creates. Must be lowercase kebab-case and short enough to fit within ElastiCache and Secrets Manager name limits (<= 32 chars). Used verbatim, so pick something like \"<app>-<env>\"."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,30}[a-z0-9])?$", var.name))
    error_message = "name must start with a letter, contain only lowercase letters, digits, and dashes, end with an alphanumeric, and be <= 32 characters."
  }
}

variable "num_replicas" {
  description = "Number of read replicas to provision behind the primary. 0 means single-node, no HA. Setting > 0 enables Multi-AZ and automatic failover."
  type        = number
  default     = 0

  validation {
    condition     = var.num_replicas >= 0 && var.num_replicas <= 5
    error_message = "num_replicas must be between 0 and 5."
  }
}

variable "parameter_group_parameters" {
  description = "Map of Valkey parameters to override on the module-managed parameter group. Use this for tuning eviction policy, keyspace notifications, etc. Keys/values map directly to ElastiCache parameter names and values."
  type        = map(string)
  default     = {}
}

variable "size" {
  description = "T-shirt size that selects the node instance type. xsmall: cache.t4g.micro, small: cache.t4g.small, medium: cache.t4g.medium, large: cache.m7g.large, xlarge: cache.m7g.xlarge."
  type        = string
  default     = "small"

  validation {
    condition     = contains(["xsmall", "small", "medium", "large", "xlarge"], var.size)
    error_message = "size must be one of: xsmall, small, medium, large, xlarge."
  }
}

variable "standard_secret_access" {
  description = "Access control for the standard-user-credentials secret (+@all -@admin -@dangerous). readers: IAM role/user ARNs (aws:PrincipalArn form -- NOT assumed-role session ARNs) allowed to GetSecretValue; every other principal is denied, and readers must also hold kms:Decrypt on the secrets CMK (see secrets_kms_key_arn output). writers: additional ARNs allowed to PutSecretValue/UpdateSecret (the deploy caller is always a writer). Default {} means only the deploy caller can read or write this secret."
  type = object({
    readers = optional(list(string), [])
    writers = optional(list(string), [])
  })
  default = {}
}

variable "subnet_ids" {
  description = "Subnets the ElastiCache subnet group covers. Must all live in the same VPC. The VPC is derived from the first subnet, so all subnets must be in that VPC."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "at least one subnet_id is required."
  }

  validation {
    condition     = alltrue([for s in var.subnet_ids : can(regex("^subnet-[a-f0-9]+$", s))])
    error_message = "every subnet_ids entry must be a valid subnet ID (subnet-...)."
  }
}

variable "tags" {
  description = "Tags applied to every taggable resource the module creates. Must include an \"environment\" key."
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "environment")
    error_message = "tags must include an \"environment\" key."
  }
}

# tflint-ignore: dave_no_vpc_id_variable # Variable is optional, so we can support shared subnets from RAM.
variable "vpc_id" {
  description = "VPC ID the ElastiCache cluster is deployed into. Must match the VPC of the provided subnets. Only needed if subnets are from a different account."
  type        = string
  default     = null

  validation {
    condition     = null || can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (vpc-...)."
  }
}

locals {
  size_to_node_type = {
    xsmall = "cache.t4g.micro"
    small  = "cache.t4g.small"
    medium = "cache.t4g.medium"
    large  = "cache.m7g.large"
    xlarge = "cache.m7g.xlarge"
  }

  node_type = local.size_to_node_type[var.size]

  parameter_group_family = "valkey${split(".", var.engine_version)[0]}"

  port = 6379

  maintenance_window = format(
    "sun:%02d:%02d-sun:%02d:%02d",
    random_integer.maintenance_hour.result,
    random_integer.maintenance_minute.result,
    random_integer.maintenance_hour.result + 2,
    random_integer.maintenance_minute.result,
  )

  # issuer_arn resolves an assumed-role session to the underlying role ARN --
  # stable, and what aws:PrincipalArn evaluates to at request time.
  caller_arn = data.aws_iam_session_context.current.issuer_arn

  account_root_arn = provider::aws::arn_build(
    data.aws_partition.current.partition,
    "iam",
    "",
    data.aws_caller_identity.current.account_id,
    "root",
  )

  # KMS administrators: the caller plus any operator-supplied roles.
  kms_admin_arns = distinct(concat([local.caller_arn], var.kms_admin_arns))

  # Per-secret writer sets -- the caller is always a writer so the module can
  # manage the secret.
  admin_secret_writer_arns    = distinct(concat(var.admin_secret_access.writers, [local.caller_arn]))
  standard_secret_writer_arns = distinct(concat(var.standard_secret_access.writers, [local.caller_arn]))

  # Per-secret read-Deny exemptions -- listed readers plus the caller (the
  # provider still reads the secret during plan for write-only versions,
  # hashicorp/terraform-provider-aws#42383).
  admin_secret_reader_exemptions    = distinct(concat(var.admin_secret_access.readers, [local.caller_arn]))
  standard_secret_reader_exemptions = distinct(concat(var.standard_secret_access.readers, [local.caller_arn]))

  vpc_id = var.vpc_id != null ? var.vpc_id : data.aws_subnet.first[0].vpc_id
}
