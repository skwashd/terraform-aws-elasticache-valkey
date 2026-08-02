# Starter .tflint.hcl for projects using the terraform-review skill.
# Enables tflint-ruleset-aws and tflint-ruleset-dave-says.
#
# Copy this to your repository root and run `tflint --init` to download
# the plugins. Pin the versions to whatever is current at adoption time;
# the values below were current as of writing.

plugin "aws" {
  enabled = true
  version = "0.47.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "dave-says" {
  enabled = true
  version = "0.4.0"
  source  = "github.com/skwashd/tflint-ruleset-dave-says"
}