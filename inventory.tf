resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible/hosts.ini.tpl", {
    ubuntu_ips    = aws_instance.ubuntu_instances[*].private_ip
    amazon_ips    = aws_instance.amazon_instances[*].private_ip
    controller_ip = aws_instance.ansible_controller.private_ip
  })

  filename = "${path.module}/ansible/hosts.ini"
}
