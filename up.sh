# !/bin/bash

set -e

# Build AMIs using packer
packer build \
  -var "ssh_keypair_name=${SSH_KEY_NAME}" \
  -var "ssh_private_key_file=${SSH_KEY_PATH}" \
  packer/ami.pkr.hcl | tee packer_output.txt

# Extract AMI IDs
sed -n 's/^.*ubuntu.amazon-ebs.ubuntu: AMI: \(ami-[a-zA-Z0-9]*\).*$/\1/p' packer_output.txt > ubuntu_ami_id.txt
sed -n 's/^.*amazon-linux.amazon-ebs.amazon_linux: AMI: \(ami-[a-zA-Z0-9]*\).*$/\1/p' packer_output.txt > amazon_ami_id.txt

# Get your IP for SG rule
export TF_VAR_my_ip="$(curl -s https://checkip.amazonaws.com)/32"

# Run Terraform
terraform init
terraform apply -auto-approve

# Get terraform outputs dynamically
ANSIBLE_CONTROLLER_IP=$(terraform output -raw ansible_controller_ip)
BASTION_PUBLIC_IP=$(terraform output -raw bastion_public_ip)

# Wait briefly to ensure EC2 instances are reachable
echo "Waiting for instances to initialize..."
sleep 30

# Copy SSH key into Ansible Controller
scp -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no "${SSH_KEY_PATH}" ec2-user@"${BASTION_PUBLIC_IP}":~/awskey.pem
ssh -A -i "${SSH_KEY_PATH}" ec2-user@"${BASTION_PUBLIC_IP}" "scp -o StrictHostKeyChecking=no awskey.pem ubuntu@${ANSIBLE_CONTROLLER_IP}:/home/ubuntu/.ssh/awskey.pem && rm awskey.pem"

# Copy Ansible files (hosts.ini and main.yml) into controller
scp -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no ansible/{hosts.ini,main.yml} ec2-user@"${BASTION_PUBLIC_IP}":~/
ssh -A -i "${SSH_KEY_PATH}" ec2-user@"${BASTION_PUBLIC_IP}" "scp -o StrictHostKeyChecking=no hosts.ini main.yml ubuntu@${ANSIBLE_CONTROLLER_IP}:/home/ubuntu/ && rm hosts.ini main.yml"

# Set permissions on controller and run Ansible playbook
ssh -A -i "${SSH_KEY_PATH}" ec2-user@"${BASTION_PUBLIC_IP}" "ssh -o StrictHostKeyChecking=no ubuntu@${ANSIBLE_CONTROLLER_IP} 'chmod 400 ~/.ssh/awskey.pem && sudo apt update && sudo apt install -y ansible && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts.ini main.yml'"

# Clean up temporary files
rm packer_output.txt ubuntu_ami_id.txt amazon_ami_id.txt

echo "Automation complete ✅"