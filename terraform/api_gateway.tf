resource "aws_api_gateway_rest_api" "parolo" {
  name = "parolo"
}

resource "aws_api_gateway_method" "slack_webhook" {
  rest_api_id   = "${aws_api_gateway_rest_api.parolo.id}"
  resource_id   = "${aws_api_gateway_rest_api.parolo.root_resource_id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.parolo.id}"
  resource_id             = "${aws_api_gateway_rest_api.parolo.root_resource_id}"
  http_method             = "${aws_api_gateway_method.slack_webhook.http_method}"
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.parolo.arn}/invocations"
}

resource "aws_lambda_permission" "apigw_lambda_parolo" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.parolo.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn =
  "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.parolo.id}/*/${aws_api_gateway_method.slack_webhook.http_method}/"
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.parolo.id}"
  resource_id = "${aws_api_gateway_rest_api.parolo.root_resource_id}"
  http_method = "${aws_api_gateway_method.slack_webhook.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = "${aws_api_gateway_rest_api.parolo.id}"
  resource_id = "${aws_api_gateway_rest_api.parolo.root_resource_id}"
  http_method = "${aws_api_gateway_method.slack_webhook.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
}

resource "aws_api_gateway_deployment" "parolo" {
  depends_on = ["aws_api_gateway_method.slack_webhook"]

  rest_api_id = "${aws_api_gateway_rest_api.parolo.id}"
  stage_name  = "prod"
}
