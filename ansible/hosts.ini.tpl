[ubuntu_instances]
%{ for idx, ip in ubuntu_ips ~}
ubuntu${idx + 1} ansible_host=${ip} ansible_user=ubuntu
%{ endfor ~}

[amazon_instances]
%{ for idx, ip in amazon_ips ~}
amazon${idx + 1} ansible_host=${ip} ansible_user=ec2-user
%{ endfor ~}

[ansible_controller]
controller ansible_host=${controller_ip} ansible_user=ubuntu

[all:vars]
ansible_ssh_private_key_file=~/.ssh/awskey.pem