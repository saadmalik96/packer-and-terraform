variable "ssh_keypair_name" {
  type        = string
  description = "Name of the EC2 key pair registered in AWS"
}

variable "ssh_private_key_file" {
  type        = string
  description = "Path to the private key file for SSH"
}

source "amazon-ebs" "docker_ami" {
  region                  = "us-east-1"
  source_ami_filter {
    filters = {
      name = "amzn2-ami-hvm-*-x86_64-gp2"
    }
    owners      = ["137112412989"]
    most_recent = true
  }

  instance_type           = "t2.micro"
  ssh_username            = "ec2-user"
  ssh_keypair_name        = var.ssh_keypair_name
  ssh_private_key_file    = var.ssh_private_key_file
  ami_name                = "amazon-linux-docker-${formatdate("YYYYMMDDhhmmss", timestamp())}"
}

build {
  sources = ["source.amazon-ebs.docker_ami"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user"
    ]
  }
}
