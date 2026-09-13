# Runbook — subir e derrubar o Cloud SQL

Este banco fica ligado 24h consumindo cota enquanto existir. Para economizar
crédito entre sessões de trabalho, é seguro destruir tudo aqui e recriar
depois — nenhum dado é necessário entre uma sessão e outra até que o schema
esteja estável. **Não destrua isso perto da entrega final**: os avaliadores
precisam acessar o ambiente ativo, então a partir do momento em que a
demonstração for gravada, deixe tudo de pé até a avaliação terminar.

## Pré-requisitos (uma vez só, não precisa repetir)

- `gcloud` autenticado (`gcloud auth login` e `gcloud auth application-default login`)
  com o projeto certo (`gcloud config set project oficina-501820`).
- CLIs instaladas: `brew install cloud-sql-proxy flyway`.
- APIs já habilitadas no projeto (`sqladmin.googleapis.com`,
  `secretmanager.googleapis.com`) — isso não é destruído pelo `terraform destroy`.
- Bucket de state `gs://oficina-501820-tfstate` — também não é destruído.

## Derrubar (economizar crédito)

Dentro da pasta local deste repositório, na branch `main` atualizada:

```bash
terraform destroy -var-file=terraform.tfvars
```

Confirme com `yes`. Isso apaga: a instância Cloud SQL (e os dois bancos
dentro dela), os secrets no Secret Manager, a service account e as
permissões IAM associadas. Não apaga o bucket de state nem nada no GitHub.

## Recriar

1. Aplicar o Terraform:

   ```bash
   terraform apply -var-file=terraform.tfvars
   ```

   Confirme com `yes`. Leva alguns minutos (a instância é o item mais lento).

   > A senha e o IP público gerados são novos a cada recriação — não são os
   > mesmos da vez anterior. Nunca copie a senha antiga de um lugar salvo;
   > sempre busque a atual no Secret Manager (próximo passo).

2. Abrir o túnel do Cloud SQL Auth Proxy (deixe rodando numa aba separada):

   ```bash
   cloud-sql-proxy oficina-501820:southamerica-east1:oficina-postgres --port 5432
   ```

3. Em outra aba, buscar a senha atual e rodar as migrations nos dois bancos:

   ```bash
   export DB_PASSWORD=$(gcloud secrets versions access latest --secret=oficina-db-password)
   LOC=/Users/robsonoliveira/Documents/pos/3-fase/git/oficina/src/main/resources/db/migration

   flyway -url=jdbc:postgresql://localhost:5432/oficina_homolog -user=oficina -password="$DB_PASSWORD" -locations=filesystem:$LOC migrate
   flyway -url=jdbc:postgresql://localhost:5432/oficina_producao -user=oficina -password="$DB_PASSWORD" -locations=filesystem:$LOC migrate
   ```

4. Conferir que os dois aplicaram (`State: Success`):

   ```bash
   flyway -url=jdbc:postgresql://localhost:5432/oficina_homolog -user=oficina -password="$DB_PASSWORD" -locations=filesystem:$LOC info
   flyway -url=jdbc:postgresql://localhost:5432/oficina_producao -user=oficina -password="$DB_PASSWORD" -locations=filesystem:$LOC info
   ```

## Erros comuns

- `password is an empty string`: `DB_PASSWORD` não está definida nessa aba de
  terminal (variável de ambiente não atravessa abas/janelas). Exporte de novo
  na mesma aba onde vai rodar o `flyway`.
- `No migrations found` / caminho duplicado nas `locations`: o comando foi
  rodado de dentro da própria pasta `db/migration`, fazendo o caminho
  relativo se repetir. Use sempre o caminho absoluto, como nos exemplos acima.
- `Invalid Tier ... for ENTERPRISE_PLUS Edition`: se esse erro voltar a
  aparecer em uma recriação futura, confirme que `main.tf` ainda declara
  `edition = "ENTERPRISE"` no bloco `settings` da instância.
