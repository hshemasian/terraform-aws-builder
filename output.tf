output "builder_ip" {
  description = "Public IP address of the machine"
  value       = module.compute.builder_ip
}

output "ssh_command" {
  description = "Command for SSH"
  value       = "ssh -i builder-key.pem ubuntu@${module.compute.builder_ip}"
}