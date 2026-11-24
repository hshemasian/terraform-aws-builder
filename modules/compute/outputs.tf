output "builder_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.builder.public_ip
}