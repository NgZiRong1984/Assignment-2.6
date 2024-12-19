variable "environment" {
  type    = string
  default = "dev"
}


resource "aws_dynamodb_table" "zirong_table" {
  name           = "Zirong-dynamodb"
   billing_mode = "PAY_PER_REQUEST"
  hash_key       = "ISBN"           # Partition Key
  range_key      = "Genre"          # Sort Key
 # Define the attributes for the keys
  attribute {
    name = "ISBN"                 # Partition Key Attribute
    type = "S"                    # S = String
  }

  attribute {
    name = "Genre"                # Sort Key Attribute
    type = "S"                    # S = String
  }

}

resource "aws_dynamodb_table_item" "item_1" {
  depends_on = [aws_dynamodb_table.zirong_table]
  table_name = "Zirong-dynamodb"
  hash_key   = "ISBN"
  range_key  = "Genre"

  item = <<ITEM
{
  "ISBN": {"S": "978-0134685991"},
  "Genre": {"S": "Technology"},
  "Title": {"S": "Effective Java"},
  "Author": {"S": "Joshua Bloch"},
  "Stock": {"N": "1"}
}
ITEM
lifecycle {
    ignore_changes = [table_name]
}
}

resource "aws_dynamodb_table_item" "item_2" {
  table_name = "Zirong-dynamodb"
  hash_key   = "ISBN"
  range_key  = "Genre"

  item = <<ITEM
{
  "ISBN": {"S": "978-0134685009"},
  "Genre": {"S": "Technology"},
  "Title": {"S": "Learning Python"},
  "Author": {"S": "Mark Lutz"},
  "Stock": {"N": "2"}
}
ITEM
lifecycle {
    ignore_changes = [table_name]
}
}

resource "aws_dynamodb_table_item" "item_3" {
  table_name = "Zirong-dynamodb"
  hash_key   = "ISBN"
  range_key  = "Genre"

  item = <<ITEM
{
  "ISBN": {"S": "974-0134789698"},
  "Genre": {"S": "Fiction"},
  "Title": {"S": "The Hitchhiker"},
  "Author": {"S": "Douglas Adams"},
  "Stock": {"N": "10"}
}
ITEM
lifecycle {
    ignore_changes = [table_name]
}
}

resource "aws_dynamodb_table_item" "item_4" {
  table_name = "Zirong-dynamodb"
  hash_key   = "ISBN"
  range_key  = "Genre"

  item = <<ITEM
{
  "ISBN": {"S": "982-01346653457"},
  "Genre": {"S": "Fiction"},
  "Title": {"S": "Dune"},
  "Author": {"S": "Frank Herbert"},
  "Stock": {"N": "8"}
}
ITEM
lifecycle {
    ignore_changes = [table_name]
}
}

resource "aws_dynamodb_table_item" "item_5" {
  table_name = "Zirong-dynamodb"
  hash_key   = "ISBN"
  range_key  = "Genre"

  item = <<ITEM
{
  "ISBN": {"S": "978-01346854325"},
  "Genre": {"S": "Technology"},
  "Title": {"S": "System Design"},
  "Author": {"S": "Mark Lutz"}
}
ITEM
lifecycle {
    ignore_changes = [table_name]
}
}



resource "aws_iam_policy" "dynamodb_list_read" {
  name        = "zirong-dynamodb-read-${var.environment}"
  description = "Policy granting all List and Read actions on a specific DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeExport",
          "dynamodb:DescribeGlobalTable",
          "dynamodb:DescribeGlobalTableSettings",
          "dynamodb:DescribeKinesisStreamingDestination",
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeTableReplicaAutoScaling",
          "dynamodb:DescribeTimeToLive",
        ],
        Resource = [
          "arn:aws:dynamodb:ap-southeast-1:123456789012:table/Zirong-dynamodb", # Replace with your AWS account ID
          #"arn:aws:dynamodb:us-east-1:123456789012:table/zirong-dynamodb-read/index/*" # Optional: Include indexes
        ]
      }
    ]
  })
}

# Output to show the ARN of the created policy
output "dynamodb_read_policy_arn" {
  value = aws_iam_policy.dynamodb_list_read.arn
}

# Create the IAM Role for EC2
resource "aws_iam_role" "zirong_dynamodb_read_role" {
  name               = "zirong-dynamodb-read-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the custom zirong-dynamodb-read policy to the IAM role
resource "aws_iam_role_policy_attachment" "zirong_dynamodb_read_policy_attachment" {
  role       = aws_iam_role.zirong_dynamodb_read_role.name
  policy_arn = aws_iam_policy.dynamodb_list_read.arn  # Dynamically use the ARN of the custom policy
}

# Create an instance profile for the EC2 role
resource "aws_iam_instance_profile" "zirong_dynamodb_read_instance_profile" {
  name = "zirong-dynamodb-read-instance-profile"
  role = aws_iam_role.zirong_dynamodb_read_role.name
}

# Example EC2 instance that uses the created IAM role
resource "aws_instance" "public" {
  ami                         = data.aws_ami.amazon2023.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.public.ids[0] # Use the first subnet in the list
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
 iam_instance_profile = aws_iam_instance_profile.zirong_dynamodb_read_instance_profile.name

  tags = {
    Name = "zirong-dynamodb-reader"
  }
}

resource "aws_security_group" "sg" {
  name        = "zirong-dynamodb-reader-sg"
  description = "Allow inbound SSH and HTTP traffic"
  vpc_id  = data.aws_vpc.selected.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
