provider "aws" {
  region = "${var.region}"
}

resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "cd .. && yarn && cp -R node_modules src"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "parolo.zip"

  source_dir = "../src"
}

resource "aws_iam_role" "parolo_lambda" {
  name = "parolo_lambda"

  depends_on = ["null_resource.build"]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec_role" {
    role       = "${aws_iam_role.parolo_lambda.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "parolo" {
  filename         = "parolo.zip"
  function_name    = "parolo"
  role             = "${aws_iam_role.parolo_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs6.10"
  timeout          = "120"

  environment {
    variables = {
      SLACK_MESSAGE_COUNT = "${var.slack_message_count}"
      SLACK_TOKEN = "${var.slack_token}"
      PGHOST = "${var.pg_host}"
      PGDATABASE = "${var.pg_database}"
      PGUSER = "${var.pg_user}"
      PGPASSWORD = "${var.pg_password}"
    }
  }

  tags {
    Name = "parolo"
  }
}
