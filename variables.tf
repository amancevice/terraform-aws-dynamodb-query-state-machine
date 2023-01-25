############
#   ROLE   #
############

variable "role" {
  description = "State machine IAM role configuration"
  type = object({
    description = optional(string)
    name        = optional(string)
    path        = optional(string)
  })
  default = {}
}

#####################
#   STATE MACHINE   #
#####################

variable "allowed_callbacks" {
  description = "State machine names that may be invoked as a callback"
  type        = list(string)
  default     = []
}

variable "name" {
  description = "State machine name"
  type        = string
}

variable "logging_configuration" {
  description = "State machine logging configuration"
  type = object({
    include_execution_data = optional(bool)
    level                  = optional(string)
    log_destination        = optional(string)
  })
  default = {}
}

variable "tracing_configuration" {
  description = "State machine tracing configuration"
  type        = object({ enabled = optional(bool) })
  default     = {}
}

variable "type" {
  description = "State machine type"
  type        = string
  default     = "STANDARD"
}

variable "retries_dynamodb" {
  description = "Step functions DynamoDB query retry configurations"
  type = list(object({
    BackoffRate     = number
    IntervalSeconds = number
    MaxAttempts     = number
    ErrorEquals     = list(string)
  }))
  default = [{
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
}

variable "retries_states" {
  description = "Step functions state machine execution retry configurations"
  type = list(object({
    BackoffRate     = number
    IntervalSeconds = number
    MaxAttempts     = number
    ErrorEquals     = list(string)
  }))
  default = [{
    BackoffRate     = 2
    IntervalSeconds = 3
    MaxAttempts     = 4
    ErrorEquals = [
      "States.ServiceUnavailable",
      "States.ThrottlingException",
    ]
  }]
}

############
#   TAGS   #
############

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = null
}
