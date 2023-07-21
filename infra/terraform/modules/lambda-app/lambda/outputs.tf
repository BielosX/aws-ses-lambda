output "help-lambda-arn" {
  value = aws_lambda_function.lambda[local.help-lambda-name].arn
}

output "welcome-lambda-arn" {
  value = aws_lambda_function.lambda[local.welcome-lambda-name].arn
}