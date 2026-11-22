# מדפיס בסיום ההרצה את כתובת ה-IP הציבורית ש-AWS הקצתה לשרת
output "builder_ip" {
  description = "Public IP address of the machine"
  value       = aws_instance.builder.public_ip
}

# בונה ומדפיס פקודת SSH מוכנה להעתקה באמצעות אינטרפולציה (${...}) של כתובת ה-IP
output "ssh_command" {
  description = "Command for SSH"
  value       = "ssh -i builder-key.pem ubuntu@${aws_instance.builder.public_ip}"
}