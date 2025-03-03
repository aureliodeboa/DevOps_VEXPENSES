#indicando que estou usando aws e estou usando a regiao us-east-1
provider "aws" {
  region = "us-east-2"
  profile = "default"
}




/*
#estabelecendo o tipo chave que ser usado e criando a chave privada 
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#criando o par de chaves (publica) usando aquele algoritmo RSA, usando openSSH pem
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_pem 
}
*/


/*

# criando uma vpc no nosso caso ja existe com uso free de uma conta na AWS e por isso não irei criar outra
#pois teria custos a mais para criar 



resource "aws_vpc" "main_vpc" {
cidr_block           = "10.0.0.0/16"
enable_dns_support   = true
enable_dns_hostnames = true

tags = {
  Name = "${var.projeto}-${var.candidato}-vpc"
}
}

# e aqui iria criar uma subnet para essa vpc, pois para rodar um sevico na aws é necessario pelo menos uma subnet necessariamente

resource "aws_subnet" "main_subnet" {
vpc_id            = aws_vpc.main_vpc.id
cidr_block        = "10.0.1.0/24"
availability_zone = "us-east-1a"

tags = {
  Name = "${var.projeto}-${var.candidato}-subnet"
}
}

#conectando minha vpc criada à internet

resource "aws_internet_gateway" "main_igw" {
vpc_id = aws_vpc.main_vpc.id

tags = {
  Name = "${var.projeto}-${var.candidato}-igw"
}
}

#criando uma tabela roteamento para minha VPC

resource "aws_route_table" "main_route_table" {
vpc_id = aws_vpc.main_vpc.id

route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main_igw.id
}

tags = {
  Name = "${var.projeto}-${var.candidato}-route_table"
}
}

resource "aws_route_table_association" "main_association" {
subnet_id      = aws_subnet.main_subnet.id
route_table_id = aws_route_table.main_route_table.id

tags = {
  Name = "${var.projeto}-${var.candidato}-route_table_association"
}
}

*/

#regras  de entrada e saida do grupo de segurança  e a criação do proprio grupo de segurança

resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o trafego de saida"
  vpc_id      = var.vpc-id

  # Regras de entrada
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  # Regras de entrada para o nginx precisa da porta 80 liberada para rodar
  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regras de saída 
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
}
/*
data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}
*/


data "aws_key_pair" "estagio_teste" {
  key_name = "estagio-teste"  # Nome do par de chaves existente
  
}

#criando uma EC2 (uma instacia de  vm)
resource "aws_instance" "debian_ec2" {
  #ami             = data.aws_ami.debian12.id

  ami = "ami-0cb91c7de36eed2cb"
  instance_type   = "t2.micro"
  subnet_id       = var.subnet-id
  #key_name        = aws_key_pair.ec2_key_pair.key_name
  key_name        = data.aws_key_pair.estagio_teste.key_name
  
  #security_groups = [aws_security_group.main_sg.name]
  vpc_security_group_ids = ["sg-0b9f4c5ee9225c8c4"]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

    user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx
              EOF


  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

