output "wordpress_eip" {
  value = aws_eip.wordpress_eip.public_ip
}
