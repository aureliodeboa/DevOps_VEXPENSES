# Projeto Terraform - Infraestrutura na AWS

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
   - Ou esteja usando Ubuntu de forma nativa.

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
git clone <https://github.com/aureliodeboa/Devolps--VEXPENSES>
cd <Devolps--VEXPENSES>
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

## Considerações Finais

- **Custos**: Este projeto cria recursos na AWS que podem gerar custos. Certifique-se de destruir a infraestrutura após o uso.
- **Segurança**: A chave privada gerada pelo Terraform deve ser mantida em segurança. Não a compartilhe publicamente.
- **Personalização**: Sinta-se à vontade para modificar o código para atender às suas necessidades específicas.

---

## Autor

Este projeto foi desenvolvido por @aureliodeboa como parte de um teste técnico para a vexpenses.

