# oficina-infra-db

Infraestrutura do Banco de Dados Gerenciado (Terraform) do Tech Challenge
Fase 3 (Pós-Tech SOAT).

Um dos 4 repositórios exigidos pelo desafio, responsável por provisionar o
banco de dados gerenciado (Cloud SQL PostgreSQL) usado pela aplicação
principal ([`oficina`](https://github.com/robsonago/oficina)), com bancos
separados para homologação (`oficina_homolog`) e produção (`oficina_producao`)
dentro da mesma instância.

**Fase 4:** a mesma instância passa a hospedar também o banco do
[Execution Service](https://github.com/robsonago/oficina-execution-service)
(`execucao_homolog` / `execucao_producao`), com **usuário, senha (secret
`oficina-execucao-db-password`) e service account (`oficina-execucao`)
próprios** — o Execution Service não conhece as credenciais do banco do OS
Service e vice-versa. O Billing Service usa MongoDB, provisionado dentro do
cluster (ver [`oficina-infra-k8s`](https://github.com/robsonago/oficina-infra-k8s)).
Manter tudo na mesma instância é uma escolha de custo para o ambiente de
estudo; numa operação real o passo seguinte seria uma instância por serviço.

| Database | Usuário | Serviço |
|---|---|---|
| `oficina_homolog` / `oficina_producao` | `oficina` | OS Service |
| `execucao_homolog` / `execucao_producao` | `execucao` | Execution Service |

Dockerfile não se aplica a este repositório (Terraform não usa Docker).

## Stack

- Terraform >= 1.6
- Provider `hashicorp/google` ~> 6.0
- Cloud SQL para PostgreSQL 16
- Secret Manager (senha e URLs JDBC)
- State remoto em bucket GCS (`oficina-501820-tfstate`, prefixo `infra-db`)

## Pré-requisitos

- `gcloud` autenticado (`gcloud auth application-default login`) e projeto
  configurado (`gcloud config set project oficina-501820`).
- APIs habilitadas: `sqladmin.googleapis.com`, `secretmanager.googleapis.com`.
- Bucket de state já criado (`gcloud storage buckets create ...`).

## Como rodar

```bash
terraform init
terraform plan -var-file=terraform.tfvars    # copie terraform.tfvars.example
terraform apply -var-file=terraform.tfvars
```

## Saídas relevantes

- `instance_connection_name`: usado pelo Cloud SQL Auth Proxy no cluster GKE.
- `secret_db_password_id`: nome do secret no Secret Manager com a senha do
  usuário de aplicação.

> Este README será complementado com diagrama de arquitetura, diagrama ER e
> link do ambiente ativo conforme o restante da Fase 3 avança.
