variable "ssh_keypair_name" {
  type        = string
  description = "Name of the EC2 key pair registered in AWS"
}

variable "ssh_private_key_file" {
  type        = string
  description = "Path to the private key file for SSH"
}

source "amazon-ebs" "amazon_linux" {
  region                  = "us-east-1"
  source_ami_filter {
    filters = {
      name = "amzn2-ami-hvm-*-x86_64-gp2"
    }
    owners      = ["137112412989"]
    most_recent = true
  }

  instance_type        = "t2.micro"
  ssh_username         = "ec2-user"
  ssh_keypair_name     = var.ssh_keypair_name
  ssh_private_key_file = var.ssh_private_key_file
  ami_name             = "amazon-linux-docker-${formatdate("YYYYMMDDhhmmss", timestamp())}"
}

source "amazon-ebs" "ubuntu" {
  region                  = "us-east-1"
  source_ami_filter {
    filters = {
      name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  instance_type        = "t2.micro"
  ssh_username         = "ubuntu"
  ssh_keypair_name     = var.ssh_keypair_name
  ssh_private_key_file = var.ssh_private_key_file
  ami_name             = "ubuntu-docker-${formatdate("YYYYMMDDhhmmss", timestamp())}"
}

build {
  name    = "amazon-linux"
  sources = ["source.amazon-ebs.amazon_linux"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user"
    ]
  }
}

build {
  name    = "ubuntu"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ubuntu"
    ]
  }
}