variable "project_id" {
  description = "ID do projeto GCP (ex.: oficina-501820)"
  type        = string
}

variable "region" {
  description = "Região do Cloud SQL"
  type        = string
  default     = "southamerica-east1"
}

variable "instance_name" {
  description = "Nome da instância do Cloud SQL"
  type        = string
  default     = "oficina-postgres"
}

variable "tier" {
  description = "Tipo de máquina da instância (shared-core, baixo custo, adequado para carga de estudo)"
  type        = string
  default     = "db-f1-micro"
}

variable "postgres_version" {
  description = "Versão do PostgreSQL, alinhada com o que já roda em docker-compose/k8s (postgres:16-alpine)"
  type        = string
  default     = "POSTGRES_16"
}

variable "db_user" {
  description = "Usuário de aplicação do banco (mesmo usado hoje via DB_USERNAME)"
  type        = string
  default     = "oficina"
}

variable "deletion_protection" {
  description = "Proteção contra exclusão acidental da instância. Mantido em false neste projeto de estudo para permitir destruir/recriar sem fricção; considerar true antes da gravação do vídeo final."
  type        = bool
  default     = false
}
