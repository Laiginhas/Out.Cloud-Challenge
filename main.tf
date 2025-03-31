resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_sg"
  description = "Allow HTTP, HTTPS and SSH"

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

resource "aws_instance" "wordpress" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.wordpress_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable php7.4
              yum install -y httpd php php-mysqlnd mariadb unzip wget

              systemctl enable httpd
              systemctl start httpd

              systemctl enable mariadb
              systemctl start mariadb

              until mysqladmin ping --silent; do
                echo "Waiting for MySQL to start..."
                sleep 2
              done


            
              mysql -e "CREATE DATABASE wp_landing_db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
              mysql -e "CREATE USER 'wp_ricardo'@'localhost' IDENTIFIED BY 'W0rdPr3ssRic2024!';"
              mysql -e "GRANT ALL PRIVILEGES ON wp_landing_db.* TO 'wp_ricardo'@'localhost';"
              mysql -e "FLUSH PRIVILEGES;"

            
              cd /var/www/html
              wget https://wordpress.org/latest.tar.gz
              tar -xzf latest.tar.gz
              cp -r wordpress/* .
              rm -rf wordpress latest.tar.gz

             
              cp wp-config-sample.php wp-config.php
              sed -i "s/database_name_here/wp_landing_db/" wp-config.php
              sed -i "s/username_here/wp_ricardo/" wp-config.php
              sed -i "s/password_here/W0rdPr3ssRic2024!/" wp-config.php
              sed -i "s/localhost/localhost/" wp-config.php

             
              chown -R apache:apache /var/www/html
              chmod -R 755 /var/www/html

             
              yum install -y amazon-cloudwatch-agent
              cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << CONFIG
              {
                "metrics": {
                  "metrics_collected": {
                    "mem": {
                      "measurement": ["mem_used_percent"]
                    },
                    "disk": {
                      "measurement": ["used_percent"],
                      "resources": ["*"]
                    }
                  },
                  "append_dimensions": {
                    "InstanceId": "$${aws:InstanceId}"
                  }
                }
              }
              CONFIG

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
              EOF

  tags = {
    Name = "wordpress-instance"
  }
}

resource "aws_eip" "wordpress_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "wordpress_ip_assoc" {
  instance_id   = aws_instance.wordpress.id
  allocation_id = aws_eip.wordpress_eip.id
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

# Instância Blue
resource "aws_instance" "wordpress_blue" {
  count                       = local.is_blue_active ? 1 : 0
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  key_name                    = "wordpress-key"
  iam_instance_profile        = "cloudwatch-agent-instance-profile"
  subnet_id                   = "subnet-..." 
  vpc_security_group_ids      = ["${aws_security_group.wordpress_sg.id}"]
  associate_public_ip_address = false
  user_data                   = file("scripts/user_data.sh") 
  tags = {
    Name = "wordpress-blue"
  }
}

# Instância Green
resource "aws_instance" "wordpress_green" {
  count                       = local.is_green_active ? 1 : 0
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  key_name                    = "wordpress-key"
  iam_instance_profile        = "cloudwatch-agent-instance-profile"
  subnet_id                   = "subnet-..." 
  vpc_security_group_ids      = ["${aws_security_group.wordpress_sg.id}"]
  associate_public_ip_address = false
  user_data                   = file("scripts/user_data.sh")
  tags = {
    Name = "wordpress-green"
  }
}

# Associação do EIP à instância ativa
resource "aws_eip_association" "wordpress_ip_assoc" {
  instance_id   = local.is_blue_active ? aws_instance.wordpress_blue[0].id : aws_instance.wordpress_green[0].id
  allocation_id = aws_eip.wordpress_eip.id
}

