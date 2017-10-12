# Parolo

Parolo smoothly forwards all your public Slack messages to an AWS Lambda function and stores them in PostgreSQL.

![Marco Parolo](https://upload.wikimedia.org/wikipedia/commons/0/0d/Dnepr-Lazio_%287%29.jpg)

## 1. Create a Slack App

Start here: https://api.slack.com/apps

Take note of the "Client ID" and the Client Secret".

## Deploy :rocket:

In a new directory, create a file `main.tf` with the following content:

```
module "parolo" {
  source  = "github.com/buildo/parolo"

  name = "" # Unique name for this parolo installation
  aws_account_id = "" # AWS Account ID
  aws_region = "" # AWS Region

  slack_token = "" # Slack API Token
  slack_verification_token = "" # Slack App Verification Token

  pg_host = "" # Postgres host
  pg_database = "" # Postgres DB name
  pg_user = "" # Postgres user
  pg_password = "" # Postgres password
  account_id = "" # AWS Account ID
}
```

Then spin up the infra using Terraform:

```sh
terraform init
terraform apply
```

This will create:

* an AWS Lambda function
* an AWS API Gateway
* lots of AWS glue to make it all work


## 3. Configure the Slack App to forward messages

Find your new API Gateway endpoint:

```sh
terraform show | grep invoke_url
```

Then in the "Event Subscriptions" section of your Slack App configuration,
enable events, paste the API Gateway endpoint and select `message:channels` from
the list of events.

Finally remember to install the app to your workspace from the "Basic
Information" section.
