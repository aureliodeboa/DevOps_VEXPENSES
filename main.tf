#indicando que estou usando aws e estou usando a regiao us-east-1
provider "aws" {
  region = "us-east-2"
  profile = "default"
}

#estabelecendo o tipo chave que ser usado e criando a chave privada com tamanho de 2048
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#criando o par de chaves (publica) usando algoritmo RSA de criptografia assimetrica, usando openSSH pem
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh 
}



/*
# eu deixei isso tudo comentado para enfatizar que usando os recursos já disponiveis não é necessario criar outra VPC, sendo assim diminuindo os custos


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
  #aqui já estou usando o id da vpc que ja é existente quando cria-se uma conta aws
  vpc_id      = var.vpc-id


  # Regras de entrada
  #regra do ssh sempre na porta 22, entretanto o ideal seria definir um ip especifico para entrar via ssh
  #pois assim teriamos mais segurança, se trantando de um teste tecnico queria deixar isso claro, entendo que é uma vunerabilidade e em um caso real
  #seria o ideal restringir o acesso a ips especificos
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

#aqui são definidos os dados que serão usados para a consulta da maquina da EC2, lembrando que isso aqui não cria nada, apenas busca informações
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



#criando uma EC2 (uma instacia de  vm), aqui sim será criado uma EC2 
resource "aws_instance" "debian_ec2" {
  
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = var.subnet-id #todo recurso na AWS precisa de pelo menos uma subnet para funcionar, como eu desconsiderei essa criação la em cima aqui eu coloco o id de um subnet existente
  key_name        = aws_key_pair.ec2_key_pair.key_name

  
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  
 #security_groups = [aws_security_group.main_sg.name] havia um erro usando essa linha por isso optei pela de cima

  associate_public_ip_address = true

#definindo tamanho do volume do disco e o tipo de codificação dos dados, e caso eu exclua o a maquina eu excluo o disco tmb
  root_block_device {
    volume_size           = 20  # Tamanho do volume em GB
    volume_type           = "gp2"
    delete_on_termination = true # Excluir o volume ao encerrar a instância
  }
  #passo para instalar o nginx, lembrando que eu abri a porta 80 para que ele funcione
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

