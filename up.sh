packer build \
  -var "ssh_keypair_name=${SSH_KEY_NAME}" \
  -var "ssh_private_key_file=${SSH_KEY_PATH}" \
  packer/ami.pkr.hcl | tee packer_output.txt

grep 'us-east-1:' packer_output.txt | awk '{print $2}' > ami_id.txt

rm packer_output.txt

export TF_VAR_my_ip="$(curl -s https://checkip.amazonaws.com)/32"

terraform init
terraform apply -auto-approve

rm ami_id.txt