# Parolo

Parolo lets you forward all your Slack messages to AWS Lambda and store them in PostgreSQL.

![Marco Parolo](https://upload.wikimedia.org/wikipedia/commons/0/0d/Dnepr-Lazio_%287%29.jpg)

## Deploy

Create a file `terraform/secret.tfvars` containing the following vars:

```
slack_token = "" # Slack API Token
slack_verification_token = "" Slack App Verification Token
pg_host = "" Postgres host
pg_database = "" Postgres DB name
pg_user = "" Postgres user
pg_password = "" Postgres password
slack_message_count = "" How many messages to fetch for each channel
account_id = "" AWS Account ID
```

Then spin up the infra using Terraform

```
cd terraform
terraform apply -var-file=secret.tfvars
```

It will create:

* an AWS Lambda function
* an AWS API Gateway
* lots of AWS glue to make it all work
