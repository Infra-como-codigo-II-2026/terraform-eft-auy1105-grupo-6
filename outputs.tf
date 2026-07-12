output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.networking.vpc_id
}

output "instance_id" {
  description = "ID de la instancia EC2 creada"
  value       = module.compute.instance_id
}

output "instance_ip" {
  description = "IP publica de la instancia EC2"
  value       = module.compute.instance_ip
}