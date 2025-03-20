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