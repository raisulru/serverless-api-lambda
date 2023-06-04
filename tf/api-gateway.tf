resource "aws_api_gateway_rest_api" "data_server" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "data-server"
      version = "1.0"
    }
    paths = {
      "/" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  })

  name = "${var.prefix}-data-server"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "data_server_deployment" {
  rest_api_id = aws_api_gateway_rest_api.data_server.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.data_server.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev_stage" {
  deployment_id = aws_api_gateway_deployment.data_server_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.data_server.id
  stage_name    = "${var.prefix}-dev"
}
