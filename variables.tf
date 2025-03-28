variable "instance_type" {
  description = "Tipo da instância EC2"
  default     = "t2.micro"
}

variable "key_name" {
  description = "wordpress-key"
  type        = string
}