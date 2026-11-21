output "builder_ip" {
  description = "Public IP address of the machine"
  value       = aws_instance.builder.public_ip
}

output "ssh_command" {
  description = "Command for SSH"
  value       = "ssh -i builder-key.pem ubuntu@${aws_instance.builder.public_ip}"
}