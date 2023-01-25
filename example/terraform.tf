provider "aws" {
  region = "us-west-2"
}

module "dynamodb_query" {
  source = "../"

  ################
  #   REQUIRED   #
  ################

  name = "my-dynamodb-query"

  ################
  #   OPTIONAL   #
  ################

  allowed_callbacks = ["my-example-state-machine"]
  type              = "STANDARD" # "EXPRESS"

  logging_configuration = {
    include_execution_data = false
    level                  = "ALL"
    log_destination        = "<log-arn>"
  }

  retries_dynamodb = [{
    BackoffRate     = 2
    IntervalSeconds = 3
    MaxAttempts     = 4
    ErrorEquals = [
      "DynamoDB.InternalServerErrorException",
      "DynamoDB.ItemCollectionSizeLimitExceededException",
      "DynamoDB.LimitExceededException",
      "DynamoDB.RequestLimitExceeded",
      "DynamoDB.ThrottlingException",
    ]
  }]

  retries_states = [{
    BackoffRate     = 2
    IntervalSeconds = 3
    MaxAttempts     = 4
    ErrorEquals = [
      "States.ServiceUnavailable",
      "States.ThrottlingException",
    ]
  }]

  role = {
    description = "My role description"
    name        = "my-dynamodb-query-us-west-2"
    path        = "/states/"
  }

  tags = {
    "git:repo" = "amancevice/terraform-aws-dynamodb-query-state-machine"
  }

  tracing_configuration = {
    enabled = true
  }
}
