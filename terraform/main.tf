provider "aws" {
region = "eu-west-3" # Paris
}

# 🏗️ Création du rôle IAM pour la Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "g7-lambda_execution_role"

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

# 📌 Attachement de la politique AWS de base pour Lambda (modifié pour éviter l'erreur d'autorisation)
resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 📂 Compression du code en ZIP avant le déploiement
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/index.js" # Assurez-vous que ce fichier existe
  output_path = "lambda_function.zip"
}

# 🚀 Déploiement de la Lambda
resource "aws_lambda_function" "time_lambda" {
  function_name    = "g7_get_time_lambda"
  runtime         = "nodejs18.x"
  handler         = "index.handler"
  role            = aws_iam_role.lambda_exec.arn
  filename        = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout         = 10

  environment {
    variables = {
      TZ = "Europe/Paris"
    }
  }
}

  # 🚀 Création de l'API Gateway REST
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "g7_api_gateway"
  description = "API Gateway pour la fonction Lambda"
}

# 📂 Création de la ressource (endpoint) dans l'API Gateway
resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "/g7_api" # Chemin de l'endpoint (ex: /example)
}

# 🛠️ Configuration de la méthode HTTP (GET)
resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "GET"
  authorization = "NONE" # Pas d'autorisation pour cet exemple
}

# 🔗 Intégration de la méthode avec la fonction Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.example_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.time_lambda.invoke_arn
}

# ✅ Déploiement de l'API Gateway
resource "aws_api_gateway_deployment" "example_deployment" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  stage_name  = "dev" # Nom de l'environnement (ex: prod, dev)

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

# 🔓 Donner la permission à l'API Gateway d'invoquer la Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.time_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example_api.execution_arn}/*/*"
}