variable "vpc_cidr" {
  description = "CIDR block de la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project" {
  description = "Nombre del proyecto (usado en tags)"
  type        = string
  default     = "auy1105"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "prod"
}

variable "key_name" {
  description = "Nombre de un key pair existente en AWS"
  type        = string
  default     = "vockey"
}

variable "ami" {
  description = "ID de la AMI para la instancia EC2 (si se deja vacio, se busca la ultima Amazon Linux automaticamente)"
  type        = string
  default     = ""
}