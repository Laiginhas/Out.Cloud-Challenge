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
              yum install -y httpd php php-mysqlnd mariadb
              systemctl enable httpd
              systemctl start httpd

              cd /var/www/html
              wget https://wordpress.org/latest.tar.gz
              tar -xzf latest.tar.gz
              cp -r wordpress/* .
              chown -R apache:apache /var/www/html
              chmod -R 755 /var/www/html
              rm -rf wordpress latest.tar.gz

              # Instalar CloudWatch Agent
              yum install -y amazon-cloudwatch-agent

              # Criar config mínima
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
