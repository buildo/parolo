resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "cd ${path.module}/lambda && yarn"
  }
  triggers {
    package_json = "${sha1(file("${path.module}/lambda/package.json"))}"
    yarn_lock = "${sha1(file("${path.module}/lambda/yarn.lock"))}"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/parolo.zip"

  source_dir = "${path.module}/lambda"
  depends_on = ["null_resource.build"]
}

resource "aws_lambda_function" "parolo" {
  filename         = "${path.module}/parolo.zip"
  function_name    = "parolo_${var.name}"
  role             = "${aws_iam_role.parolo_lambda.arn}"
  handler          = "src/index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs6.10"
  timeout          = "120"

  environment {
    variables = {
      SLACK_VERIFICATION_TOKEN = "${var.slack_verification_token}"
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
