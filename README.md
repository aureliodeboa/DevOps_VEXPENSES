
# Infraestrutura na AWS Desafio técnico Vexpenses

Esse repositorio é fruto de um desafio tecnico feito para uma vaga de DevOps para Vexpenses e este readmi foi construido tendo em vista cumprir todos os requisitos solicitados.

## Descrição Técnica do Código Terraform dado

### Provider AWS
```hcl
provider "aws" {
  region = "us-east-1"
}
```
- **Função**: Define o provedor AWS e a região onde os recursos serão criados.
- **Detalhes**: O provedor AWS é configurado para usar a região `us-east-1`.

### Variáveis
```hcl
variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}
```
- **Função**: Define variáveis que podem ser reutilizadas em todo o código.
- **Detalhes**:
  - `projeto`: Armazena o nome do projeto, com valor padrão `"VExpenses"`.
  - `candidato`: Armazena o nome do candidato, com valor padrão `"SeuNome"`.

### Chave Privada e Key Pair
```hcl
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}
```
- **Função**: Gera uma chave privada RSA (criptografia assimetrica) e cria um key pair.
- **Detalhes**:
  - `tls_private_key`: Gera uma chave privada RSA de 2048 bits.
  - `aws_key_pair`: Cria uma chave publica   usando a chave privada gerada. Temos assim o par de chaves.

### VPC
```hcl
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}
```
- **Função**: Cria uma VPC (Virtual Private Cloud) na AWS.
- **Detalhes**:
  - `cidr_block`: Define o bloco CIDR da VPC como `10.0.0.0/16`.
  - `enable_dns_support` e `enable_dns_hostnames`: Habilitam suporte a DNS e nomes de host.
  - `tags`: Adiciona tags para identificação.

### Subnet
```hcl
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}
```
- **Função**: Cria uma subnet dentro da VPC.
- **Detalhes**:
  - `vpc_id`: Associa a subnet à VPC criada.
  - `cidr_block`: Define o bloco CIDR da subnet como `10.0.1.0/24`.
  - `availability_zone`: Define a zona de disponibilidade como `us-east-1a`.
  - `tags`: Adiciona tags para identificação.

### Internet Gateway
```hcl
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}
```
- **Função**: Cria um Internet Gateway e o associa à VPC (para dar acesso a internet).
- **Detalhes**:
  - `vpc_id`: Associa o Internet Gateway à VPC criada.
  - `tags`: Adiciona tags para identificação.

### Route Table
```hcl
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
```
- **Função**: Cria uma tabela de rotas e define uma rota padrão para o Internet Gateway.
- **Detalhes**:
  - `vpc_id`: Associa a tabela de rotas à VPC criada.
  - `route`: Define uma rota para todo o tráfego (`0.0.0.0/0`) para o Internet Gateway.
  - `tags`: Adiciona tags para identificação.

### Route Table Association
```hcl
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}
```
- **Função**: Associa a subnet à tabela de rotas.
- **Detalhes**:
  - `subnet_id`: Associa a subnet criada.
  - `route_table_id`: Associa a tabela de rotas criada.
  - `tags`: Adiciona tags para identificação.

### Security Group
```hcl
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

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
```
- **Função**: Cria um grupo de segurança para controlar o tráfego de entrada e saída.
- **Detalhes**:
  - `ingress`: Permite tráfego SSH (porta 22) de qualquer lugar. (vunerabilidade)
  - `egress`: Permite todo o tráfego de saída.
  - `tags`: Adiciona tags para identificação.


### AMI Debian 12
```hcl
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
```
- **Função**: Obtém a AMI mais recente do Debian 12.
- **Detalhes**:
  - `most_recent`: Seleciona a AMI mais recente.
  - `filter`: Filtra por nome e tipo de virtualização.
  - `owners`: Especifica o proprietário da AMI.

### Instância EC2
```hcl
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

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
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}
```
- **Função**: Cria uma instância EC2 com Debian 12.
- **Detalhes**:
  - `ami`: Usa a AMI do Debian 12 obtida anteriormente.
  - `instance_type`: Define o tipo da instância como `t2.micro`.
  - `subnet_id`: Associa a instância à subnet criada.
  - `key_name`: Usa o key pair criado.
  - `security_groups`: Associa o grupo de segurança criado.
  - `associate_public_ip_address`: Associa um IP público à instância.
  - `root_block_device`: Configura o volume raiz com 20 GB do tipo `gp2`.
  - `user_data`: Executa comandos de atualização ao iniciar a instância.
  - `tags`: Adiciona tags para identificação.

### Outputs
```hcl
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
```
- **Função**: Define saídas que podem ser usadas após a execução do Terraform.
- **Detalhes**:
  - `private_key`: Exibe a chave privada gerada (sensível).
  - `ec2_public_ip`: Exibe o IP público da instância EC2 criada.



# Meu Projeto  Terraform com as melhorias e modificações 

Este projeto Terraform cria uma infraestrutura básica na AWS, incluindo:
- Um par de chaves SSH para acesso à instância EC2.
- Uma instância EC2 com Debian 12.
- Um grupo de segurança para permitir tráfego SSH e HTTP.
- Configuração automática do Nginx na instância EC2.

O código foi projetado para usar recursos já existentes na AWS (como VPC e Subnet) para minimizar custos e simplificar a implantação.
## Pré-requisitos

Antes de executar este código, certifique-se de que você tem o seguinte configurado:

1. **Conta AWS**:
   - Uma conta na AWS com permissões para criar recursos como EC2, VPC, Security Groups, etc.
   - Credenciais da AWS configuradas no seu ambiente. Você pode fazer isso usando o AWS CLI:
     ```bash
     aws configure
     ```
     Insira suas credenciais (`AWS Access Key ID`, `AWS Secret Access Key`, `Default region name`, etc.).

2. **Terraform instalado**:
   - Instale o Terraform no seu ambiente. No WSL (Ubuntu), siga os passos abaixo documentação (https://www.terraform.io/docs):
     ```bash
     sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
     wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
     echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
     sudo apt update && sudo apt install terraform
     ```
   - Verifique a instalação:
     ```bash
     terraform --version
     ```

3. **WSL com Ubuntu**:
   - Certifique-se de que o WSL (Windows Subsystem for Linux) com Ubuntu está instalado e funcionando corretamente.
   - Ou esteja usando Ubuntu de forma nativa.\

---

## Estrutura do Projeto

O projeto consiste nos seguintes arquivos:

1. **`main.tf`**:
   - Contém a definição dos recursos da AWS, como a instância EC2, o grupo de segurança, o par de chaves SSH, etc.

2. **`variables.tf`**:
   - Define as variáveis usadas no projeto, como o nome do projeto, candidato, ID da VPC, ID da subnet, etc.

3. **`outputs.tf`**:
   - Define as saídas do Terraform, como o endereço IP público da instância EC2 e a chave privada SSH.

---

## Como Executar o Projeto

Siga os passos abaixo para rodar o código Terraform:

### 1. Clone o repositório (se aplicável)
Se o código estiver em um repositório Git, clone-o:
```bash
git clone <https://github.com/aureliodeboa/DevOps_VEXPENSES>
cd <DevOps_VEXPENSES>
```

### 2. Inicialize o Terraform
No diretório do projeto, execute o comando abaixo para inicializar o Terraform e baixar os plugins necessários:
```bash
terraform init
```

### 3. Revise o Plano de Execução
Antes de aplicar as mudanças, revise o plano de execução para verificar quais recursos serão criados:
```bash
terraform plan
```

### 4. Aplique as Mudanças
Para criar os recursos na AWS, execute:
```bash
terraform apply
```
Confirme a execução digitando `yes` quando solicitado.

### 5. Acesse a Instância EC2
Após a execução bem-sucedida, o Terraform exibirá as saídas definidas no arquivo `outputs.tf`:
- **Chave privada SSH**: Salve a chave privada em um arquivo (por exemplo, `chave_privada.pem`) e configure as permissões:
  ```bash
  echo "$(terraform output -raw private_key)" > chave_privada.pem
  chmod 400 chave_privada.pem
  ```
- **Endereço IP público**: Use o IP público para acessar a instância via SSH:
  ```bash
  ssh  usuario@IPdaEC2 -i chave_privada.pem admin@$(terraform output -raw ec2_public_ip)/ ou o caminho da chave
  ```

### 6. Destrua a Infraestrutura (opcional)
Para remover todos os recursos criados e evitar custos adicionais, execute:
```bash
terraform destroy
```
Confirme a execução digitando `yes` quando solicitado.

---

## Variáveis do Projeto

As variáveis usadas no projeto estão definidas no arquivo `variables.tf`. Você pode personalizá-las conforme necessário:

| Variável      | Descrição                          | Valor Padrão               |
|---------------|------------------------------------|----------------------------|
| `projeto`     | Nome do projeto                    | `"VExpenses"`              |
| `candidato`   | Nome do candidato                  | `"aurelio"`                |
| `vpc-id`      | ID da VPC existente                | `"vpc-08a9953a587f1fb64"`  |
| `subnet-id`   | ID da subnet existente             | `"subnet-06c2403fde1c38993"` |

---

## Saídas do Projeto

As saídas definidas no arquivo `outputs.tf` são:

1. **Chave privada SSH**:
   - Usada para acessar a instância EC2.
   - **Observação**: Essa saída é marcada como `sensitive`, então o valor não será exibido em texto claro no terminal.

2. **Endereço IP público da instância EC2**:
   - Use esse IP para acessar a instância via SSH ou para acessar o Nginx (na porta 80).

---

## Pontos de Melhoria

### 1. **Uso de VPC Existente**
   - **Descrição**: Em vez de criar uma nova VPC do zero, é recomendável utilizar uma VPC já existente, como a VPC padrão que é criada automaticamente ao configurar uma conta na AWS.
   - **Benefícios**:
     - **Redução de Custos**: Evita a criação de recursos desnecessários, como subnets, gateways e tabelas de rotas, que já estão presentes na VPC padrão.
     - **Simplicidade**: Simplifica a infraestrutura, especialmente em ambientes onde a VPC padrão já atende às necessidades do projeto.
   - **Implementação**: Para isso, basta referenciar a VPC existente no código Terraform, utilizando o ID da VPC padrão ou de outra VPC já criada.

   **Implementação**:
   ```hcl
         resource "aws_security_group" "main_sg" {
      name        = "${var.projeto}-${var.candidato}-sg"
      description = "Permitir SSH de qualquer lugar e todo o trafego de saida"
      #aqui já estou usando o id da vpc que ja é existente  e esta no arquivo de variables.tf
      vpc_id      = var.vpc-id
         ...
    }

   ```

---

### 2. **Organização da Estrutura do Código**
   - **Descrição**: Dividir o código Terraform em múltiplos arquivos, seguindo boas práticas de organização, como separar variáveis, outputs e recursos em arquivos distintos.
   - **Benefícios**:
     - **Manutenção Facilitada**: Facilita a leitura, manutenção e escalabilidade do código.
     - **Reutilização de Código**: Permite reutilizar variáveis e outputs em outros projetos ou módulos.
     - **Clareza**: Melhora a clareza do código, tornando-o mais modular e compreensível.
   - **Implementação**: Criar arquivos separados, como:
     - `variables.tf`: Para declarar todas as variáveis.
     - `outputs.tf`: Para definir os outputs.
     - `main.tf`: Para os recursos principais.

   **Minha Estrutura**:
   ```
   terraform/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ```

---

### 3. **Acesso SSH Restrito**
   - **Descrição**: Restringir o acesso SSH à instância EC2 para endereços IPs específicos, em vez de permitir conexões de qualquer lugar (`0.0.0.0/0`).
   - **Benefícios**:
     - **Segurança Aprimorada**: Reduz o risco de ataques externos, limitando o acesso apenas a IPs confiáveis.
     - **Conformidade**: Atende a melhores práticas de segurança e requisitos de conformidade.
   - **Implementação**: Modificar as regras de entrada (`ingress`) no grupo de segurança para permitir SSH apenas de IPs específicos.

   **Exemplo de Implementação**:
   ```hcl
   ingress {
     description = "Allow SSH only from specific IPs"
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = var.allowed_ssh_ips # esses ips estão nessa variavel
   }
   ```

---

### 4. **Documentação no Código**
   - **Descrição**: Adicionar comentários no código para explicar o propósito de cada bloco de recursos, variáveis e outputs.
   - **Benefícios**:
     - **Facilita a Colaboração**: Auxilia outros desenvolvedores ou membros da equipe a entenderem o código rapidamente.
     - **Manutenção Futura**: Simplifica a manutenção e atualização do código, especialmente em projetos de longa duração.
   - **Exemplo de Comentários**:
     ```hcl
     # Cria uma VPC para o projeto
     resource "aws_vpc" "main_vpc" {
       cidr_block = "10.0.0.0/16"
       ...
     }

     # Define o nome do projeto como variável
     variable "projeto" {
       description = "Nome do projeto"
       type        = string
       default     = "VExpenses"
     }
     ```


Os pontos de melhorias também estão documentados no codigo com comentarios

---


