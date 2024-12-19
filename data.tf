# Fetch the VPC by its "Name" tag
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["shared-vpc"]
  }
}

# Fetch public subnets in the selected VPC, filtered by "Name" tag containing "public"
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}


# Fetch private subnets in the selected VPC, filtered by "Name" tag containing "private"
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Fetch the most recent Amazon Linux 2023 AMI based on name pattern
data "aws_ami" "amazon2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }

  owners = ["amazon"]
}
# Output for selected VPC
output "selected_vpc_id" {
  value = data.aws_vpc.selected.id
}

# Output for public subnets in the selected VPC
output "public_subnet_ids" {
  value = data.aws_subnets.public.ids
}

# Output for private subnets in the selected VPC
output "private_subnet_ids" {
  value = data.aws_subnets.private.ids
}

# Output for the most recent Amazon Linux 2023 AMI
output "amazon_linux_2023_ami" {
  value = data.aws_ami.amazon2023.id
}