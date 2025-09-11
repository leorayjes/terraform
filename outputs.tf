output "instance_id" {
  description = "The ID of the web server instance"
  value       = aws_instance.webserver.id
}

output "public_ip" {
  description = "The public IP address of the web server instance"
  value       = aws_instance.webserver.public_ip

}