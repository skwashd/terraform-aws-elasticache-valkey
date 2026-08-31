data "aws_subnet" "first" {
  count = var.vpc_id == "" ? 1 : 0

  id = var.subnet_ids[0]
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
