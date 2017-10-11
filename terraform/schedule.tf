resource "aws_lambda_permission" "parolo_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.parolo.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.parolo.arn}"
}

resource "aws_cloudwatch_event_rule" "parolo" {
  name                = "parolo"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "parolo"
  rule      = "${aws_cloudwatch_event_rule.parolo.name}"
  arn       = "${aws_lambda_function.parolo.arn}"
}
