variable "region" {
  default = "eu-central-1"
}

variable "account_id" {}

variable "slack_message_count" {
  description = "How many messages are fetched for each Slack channel"
  default = "100"
}
variable "slack_token" {}
variable "slack_verification_token" {}
variable "pg_host" {}
variable "pg_database" {}
variable "pg_user" {}
variable "pg_password" {}
