### Provider Setup
provider "aws" {
  profile = "default"
  region  = var.region
}



###################################
### AWS Datacenter confiugure   ###
###################################
/*
resource "aws_vpc" "webapp-vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  tags = merge(
    local.default_tags,
    var.custom_tags,
    { Name = "webapp-vpc" }
  )
}
*/

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

/*
resource "aws_iam_role_policy" "iam_for_lambda" {
  name = "iam_for_lambda_polivy"
  role = aws_iam_role.iam_for_lambda.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "eventBroker:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}
*/
resource "aws_lambda_function" "step1" {
  filename         = "step1.zip"
  function_name    = "step1"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("step1.zip")
  runtime          = "nodejs12.x"
  tags = merge(
    local.default_tags,
    var.custom_tags
  )

}


resource "aws_lambda_function" "step2" {
  filename         = "step2.zip"
  function_name    = "step2"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("step2.zip")
  runtime          = "nodejs12.x"
  tags = merge(
    local.default_tags,
    var.custom_tags
  )

}

resource "aws_lambda_function" "call" {
  filename         = "call.zip"
  function_name    = "call"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("call.zip")
  runtime          = "nodejs12.x"
  tags = merge(
    local.default_tags,
    var.custom_tags
  )

}



data "aws_iam_role" "step" {
  name = "StepFunctions-my-state-machine-tf-role-e6838479"
}

resource "aws_sfn_state_machine" "function" {
  name       = "my-state-machine-tf"
  role_arn   = data.aws_iam_role.step.arn
  definition = templatefile("demos.json", { step1 = aws_lambda_function.step1.arn, step2 = aws_lambda_function.step2.arn })
}


resource "aws_cloudwatch_event_rule" "console" {
  name        = "Successfull-StepFunction"
  description = "Just be a testin here"

  event_pattern = <<EOF
{
  "source": [
    "aws.states"
  ],
  "detail-type": [
    "Step Functions Execution Status Change"
  ],
  "detail": {
    "status": [
      "SUCCEEDED"
    ]
  }
}
EOF
  tags = merge(
    local.default_tags,
    var.custom_tags
  )

}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.console.name
  target_id = "bob"
  arn       = aws_lambda_function.call.arn
  input_path = "$.detail.output"

}


