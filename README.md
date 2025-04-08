# WordPress Challenge – Out.Cloud


This project sets up a fully automated infrastructure on AWS to host a WordPress landing page, following best practices, automation, and scalability principles.

---

##  Objective

> Deploy a WordPress application for a landing page using Infrastructure as Code (IaC) and modern DevOps practices.

---

##  Technologies & Tools

-  **Terraform** – Infrastructure as Code
-  **AWS (Free Tier)** – EC2, VPC, Subnet, SG, IAM, CloudWatch, etc.
-  **GitHub Actions** – CI/CD for automatic deployment
-  **Terratest** – Infrastructure testing with Go
-  **CloudWatch** – Basic monitoring (memory usage alert)
-  **Amazon Linux 2** with Apache, PHP, and MariaDB

##  Architecture

- Custom VPC with a public subnet
- EC2 instance with Apache and WordPress
- Elastic IP dynamically associated
- Security Group allowing SSH, HTTP, and HTTPS
- IAM role with least privilege for CloudWatch Agent
- Automated deployment via GitHub Actions
- **Blue/Green Deployment** using Terraform
- Terratest script to validate EC2 state

---

##  Blue/Green Deployment

This setup allows switching between two environments (`blue` and `green`) using a variable. Only one environment is active at a time.

##  Testing

The `ec2_test.go` file in the `tests/` folder verifies that the EC2 instance is in a running state

