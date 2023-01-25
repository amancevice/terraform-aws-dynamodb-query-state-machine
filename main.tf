#################
#   TERRAFORM   #
#################

terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

###########
#   AWS   #
###########

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

##############
#   LOCALS   #
##############

locals {
  aws = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  }

  role = {
    description = var.role.description
    name        = coalesce(var.role.name, "${local.state_machine.name}-${local.aws.region}")
    path        = var.role.path
    tags        = var.tags

    allowed_callbacks = concat(
      # Allow state machine to invoke itself
      ["arn:aws:states:${local.aws.region}:${local.aws.account_id}:stateMachine:${local.state_machine.name}"],

      # Allow state machine to invoke user-defined callback state machines
      [
        for name in coalesce(var.allowed_callbacks, []) :
        "arn:aws:states:${local.aws.region}:${local.aws.account_id}:stateMachine:${name}"
      ],
    )
  }

  state_machine = {
    name                  = var.name
    type                  = var.type
    tags                  = var.tags
    logging_configuration = var.logging_configuration
    tracing_configuration = var.tracing_configuration
  }

  retries = {
    dynamodb = var.retries_dynamodb
    states   = var.retries_states
  }
}

################
#   IAM ROLE   #
################

resource "aws_iam_role" "role" {
  description = local.role.description
  name        = local.role.name
  path        = local.role.path
  tags        = local.role.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Sid       = "AssumeFromStates"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "states.amazonaws.com" }
    }
  })

  inline_policy {
    name = "start-execution"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = {
        Sid      = "StartExecution"
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = local.role.allowed_callbacks
      }
    })
  }
}

#####################
#   STATE MACHINE   #
#####################

resource "aws_sfn_state_machine" "state_machine" {
  name     = local.state_machine.name
  tags     = local.state_machine.tags
  type     = local.state_machine.type
  role_arn = aws_iam_role.role.arn

  definition = jsonencode(yamldecode(templatefile("${path.module}/state-machine.yml", {
    DynamoDBRetries = jsonencode(local.retries.dynamodb)
    StatesRetries   = jsonencode(local.retries.states)
  })))

  logging_configuration {
    include_execution_data = local.state_machine.logging_configuration.include_execution_data
    level                  = local.state_machine.logging_configuration.level
    log_destination        = local.state_machine.logging_configuration.log_destination
  }

  tracing_configuration {
    enabled = local.state_machine.tracing_configuration.enabled
  }
}
