resource "aws_api_gateway_rest_api" "example" {
  name = "example"
}

resource "aws_api_gateway_resource" "example" {
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "example"
  rest_api_id = aws_api_gateway_rest_api.example.id
}

resource "aws_api_gateway_method" "proxy" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
}

resource "aws_api_gateway_integration" "lambda" {
  http_method = aws_api_gateway_method.proxy.http_method
  resource_id = aws_api_gateway_resource.example.id
  rest_api_id = aws_api_gateway_rest_api.example.id

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_rest_api.example.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root
  ]

  #   triggers = {
  #     # NOTE: The configuration below will satisfy ordering considerations,
  #     #       but not pick up all future REST API changes. More advanced patterns
  #     #       are possible, such as using the filesha1() function against the
  #     #       Terraform configuration file(s) or removing the .id references to
  #     #       calculate a hash against whole resources. Be aware that using whole
  #     #       resources will show a difference after the initial implementation.
  #     #       It will stabilize to only change when resources change afterwards.
  #     redeployment = sha1(jsonencode([
  #       aws_api_gateway_resource.example.id,
  #       aws_api_gateway_method.proxy.id,
  #       aws_api_gateway_integration.lambda.id,
  #       aws_api_gateway_method.proxy.id,
  #       aws_api_gateway_integration.lambda.id
  #     ]))
  #   }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = "example"
}
