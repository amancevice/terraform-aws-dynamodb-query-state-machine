# DynamoDB Query State Machine

[![terraform](https://img.shields.io/github/v/tag/amancevice/terraform-aws-dynamodb-query-state-machine?color=62f&label=version&logo=terraform&style=flat-square)](https://registry.terraform.io/modules/amancevice/dynamodb-query-state-machine/aws)
[![build](https://img.shields.io/github/actions/workflow/status/amancevice/terraform-aws-dynamodb-query-state-machine/validate.yml?logo=github&style=flat-square)](https://github.com/amancevice/terraform-aws-dynamodb-query-state-machine/actions/workflows/validate.yml)

AWS Step Function to execute DynamoDB queries with recursive pagination.

Use this state machine to execute DynamoDB queries and optionally send each page of results to a callback handler state machine.

## Example Input

Given the input:

```json
{
  "Callback": "arn:aws:states:us-west-2:123456789012:stateMachine:my-callback",
  "TableName": "MyTable",
  "IndexName": "MyIndex",
  "KeyConditionExpression": "#PKey=:PKey",
  "ExpressionAttributeNames": { "#PKey": "PKey" },
  "ExpressionAttributeValues": { ":PKey": "MyPartition" },
  "Limit": 25
}
```

The state machine will find successive pages of 25 items in the partition `MyPartition` and start a new execution of the `my-callback` state machine with each page of results as input.

If 100 items exist in the table with a `PKey` value of `MyPartition`, then the query state machine will invoke itself 3x (not including the initial invocation) and the `my-callback` state machine will be invoked 4x.

## Usage

```terraform
provider "aws" {
  region = "us-west-2"
}

module "dynamodb_query" {
  source            = "amancevice/dynamodb-query-state-machine/aws"
  name              = "my-dynamodb-query"           # required
  allowed_callbacks = ["my-callback-state-machine"] # optional
}
```

## Advanced Usage

```terraform
provider "aws" {
  region = "us-west-2"
}

module "dynamodb_query" {
  source            = "amancevice/dynamodb-query-state-machine/aws"
  name              = "my-dynamodb-query"
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
    description = "My custom role description"
    name        = "my-custom-role-name"
    path        = "/my-custom-role-path/"
  }

  tags = {
    "git:repo" = "amancevice/terraform-aws-dynamodb-query-state-machine"
  }

  tracing_configuration = {
    enabled = true
  }
}
```
