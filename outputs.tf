output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "ubuntu_instance_private_ips" {
  value = aws_instance.ubuntu_instances[*].private_ip
}

output "amazon_instance_private_ips" {
  value = aws_instance.amazon_instances[*].private_ip
}

output "ansible_controller_ip" {
  value = aws_instance.ansible_controller.private_ip
}