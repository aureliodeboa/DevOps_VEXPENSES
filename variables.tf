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

variable "vpc-id" {
  description = "ID da VPC Principal que ja existe"
  type        = string
  default     = "vpc-08a9953a587f1fb64"
} 

variable "subnet-id" {
  description = "ID da subnet "
  type        = string
  default     = "subnet-06c2403fde1c38993"
}