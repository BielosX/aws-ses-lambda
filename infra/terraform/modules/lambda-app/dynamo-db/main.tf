resource "aws_dynamodb_table" "blocked-emails-table" {
  name = "blocked-emails"
  hash_key = "email"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "email"
    type = "S"
  }
}