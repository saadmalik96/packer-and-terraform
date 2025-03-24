variable "region" {
  default = "us-east-1"
}

variable "my_ip" {
  description = "Your IP CIDR allowed to SSH into bastion"
  type        = string
}

variable "keypair_name" {
  description = "AWS key pair name"
  default     = "awskey"
  type        = string
}
