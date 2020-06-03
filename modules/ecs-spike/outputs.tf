output "ssh_login" {
  value = "ec2-user@${aws_instance.radius.key_name}"
}

output "ssh_keypair_name" {
  value = aws_key_pair.bastion_public_key_pair.key_name
}

resource "local_file" "ec2_private_key" {
  filename          = "ec2.pem"
  file_permission   = "0600"
  sensitive_content = tls_private_key.ec2.private_key_pem
}

output "ssh_private_key" {
  value = tls_private_key.ec2.private_key_pem
}
