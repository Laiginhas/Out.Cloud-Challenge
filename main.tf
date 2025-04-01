resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "wordpress-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true  

  tags = {
    Name = "wordpress-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "wordpress-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "wordpress-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_sg"
  description = "Allow HTTP, HTTPS and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["89.155.0.15/32"]
      description = "SSH"
    }

  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    }

  ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }

  egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
}

resource "aws_eip" "wordpress_eip" {
  domain = "vpc"
}


variable "active_environment" {
  description = "Which environment should be live: blue or green"
  type        = string
  default     = "blue"
}

locals {
  is_blue_active  = var.active_environment == "blue"
  is_green_active = var.active_environment == "green"
}

resource "aws_instance" "wordpress_blue" {
  count                       = local.is_blue_active ? 1 : 0
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  key_name                    = "wordpress-key"
  iam_instance_profile        = "cloudwatch-agent-instance-profile"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids      = ["${aws_security_group.wordpress_sg.id}"]
  associate_public_ip_address = true
  user_data                   = file("scripts/user_data.sh") 
  tags = {
    Name = "wordpress-blue"
  }
}

resource "aws_instance" "wordpress_green" {
  count                       = local.is_green_active ? 1 : 0
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  key_name                    = "wordpress-key"
  iam_instance_profile        = "cloudwatch-agent-instance-profile"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids      = ["${aws_security_group.wordpress_sg.id}"]
  associate_public_ip_address = true
  user_data                   = file("scripts/user_data.sh")
  tags = {
    Name = "wordpress-green"
  }
}

resource "aws_eip_association" "wordpress_ip_assoc" {
  instance_id   = local.is_blue_active ? aws_instance.wordpress_blue[0].id : aws_instance.wordpress_green[0].id
  allocation_id = aws_eip.wordpress_eip.id
}

output "blue_instance_id" {
  value       = local.is_blue_active ? aws_instance.wordpress_blue[0].id : ""
  description = "ID of the blue instance"
}
