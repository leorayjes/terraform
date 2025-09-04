resource "aws_iam_role" "admin_role" {
  name = "hackathon-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "admin_policy" {
  name = "admin-policy"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "admin_profile" {
  name = "admin-profile"
  role = aws_iam_role.admin_role.name
}

resource "aws_iam_user" "db_user" {
  name = "database-user"
  path = "/"
}

resource "aws_iam_access_key" "db_user_key" {
  user = aws_iam_user.db_user.name
}

resource "aws_iam_user_policy" "db_user_policy" {
  name = "database-access"
  user = aws_iam_user.db_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:*",
          "s3:*",
          "secrets-manager:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user" "service_account" {
  name = "hackathon-service"
}

resource "aws_iam_user_login_profile" "service_account_login" {
  user    = aws_iam_user.service_account.name
  password_reset_required = false
}

resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_group_policy" "developers_policy" {
  name  = "developers-policy"
  group = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "s3:*",
          "iam:*",
          "cloudformation:*"
        ]
        Resource = "*"
      }
    ]
  })
}