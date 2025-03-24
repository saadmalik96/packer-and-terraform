provider "aws" {
  region = var.region
}

data "external" "ami" {
  program = ["bash", "-c", "echo '{\"ami_id\":\"'$(cat ami_id.txt)'\"}'"]
}

# VPC Module (Public Module)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name               = "my-vpc"
  cidr               = "10.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.0.1.0/24"]
  private_subnets    = ["10.0.2.0/24", "10.0.3.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

# Security Group for Bastion Host (public subnet)
module "bastion_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.my_ip]
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]
}

# Security Group for Private Instances
module "private_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "private-instance-sg"
  description = "Allow SSH from bastion"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [{
    rule                     = "ssh-tcp"
    source_security_group_id = module.bastion_sg.security_group_id
  }]

  egress_rules = ["all-all"]
}

# Bastion Host (public subnet)
resource "aws_instance" "bastion" {
  ami                         = data.external.ami.result.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.bastion_sg.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.keypair_name
}

# Private EC2 Instances using your custom AMI
resource "aws_instance" "private_instances" {
  count                  = 6
  ami                    = data.external.ami.result.ami_id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
  vpc_security_group_ids = [module.private_sg.security_group_id]
  key_name               = var.keypair_name
}
