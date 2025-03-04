variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "aurelio"
}

#id da vpc que ja existe
variable "vpc-id" {
  description = "ID da VPC Principal que ja existe"
  type        = string
  default     = "vpc-08a9953a587f1fb64"
} 

#id da subnet que ja existe
variable "subnet-id" {
  description = "ID da subnet "
  type        = string
  default     = "subnet-06c2403fde1c38993"
}

# lista de ips permitidos
variable "allowed_ssh_ips" {
  description = "IPs permitidos para SSH (formato CIDR)"
  type        = list(string)
  default     = ["SEU_IP_PUBLICO"] 
}