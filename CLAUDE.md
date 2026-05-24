# CLAUDE.md

Opinionated Terraform module for AWS ElastiCache Valkey. See [README.md](README.md) for usage, variables, outputs, the sizing table, and the behaviour of each module feature.

## Orientation

- File layout follows the `terraform-review` skill conventions: `main.tf` is data sources only; resources live in service-named files (`kms.tf`, `network.tf`, `elasticache.tf`, `users.tf`, `secrets.tf`). Variables in `variables.tf` are alphabetical.

## Invariants to preserve

These are not optional knobs; do not introduce variables that defeat them. Each invariant points at the README section that describes the behaviour it guards.

- **Encryption.** Do not expose `transit_encryption_enabled` or `at_rest_encryption_enabled` as variables. See README *Hardcoded defaults*.
- **CMKs.** `aws_kms_key.cache` (cluster at-rest) and `aws_kms_key.secrets` (Secrets Manager) are module-owned. Do not add a `kms_key_id` input. See README *Features*.
- **Ingress.** The module owns the self-referencing ingress/egress rules for intra-cluster replication on the Valkey port. Don't add caller ingress rules inside the module — those belong to the caller. See README *Features*.
- **RBAC users.** Don't remove the disabled `default` user (AWS rejects user groups that omit it) and don't add an AUTH token alongside RBAC. See README *Features* for the user structure.
- **Maintenance window.** The two `random_integer` resources pick the start time once at first apply. Don't replace them with literals. See README *Maintenance window*.
- **Write-only attributes.** `aws_elasticache_user` must use `passwords_wo`, and `aws_secretsmanager_secret_version` must use `secret_string_wo`. Reverting to the non-`wo` forms leaks the cleartext password into module state. See README *State-hardening with write-only attributes*.

## Before committing

Run `scripts/validate.sh`. See README *Validation* for the individual steps.
