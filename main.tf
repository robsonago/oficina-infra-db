# ──────────────────────────────────────────
# Instância gerenciada do Cloud SQL (PostgreSQL)
# Uma única instância hospeda os bancos de homologação e produção
# (dois "compartimentos" dentro da mesma instância, para reduzir custo).
# ──────────────────────────────────────────
resource "google_sql_database_instance" "oficina" {
  name                = var.instance_name
  database_version    = var.postgres_version
  region              = var.region
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    disk_autoresize   = true

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    ip_configuration {
      ipv4_enabled = true
      # Nenhum bloco authorized_networks: nenhuma rede externa fica liberada
      # para conectar diretamente. A aplicação no GKE conecta via Cloud SQL
      # Auth Proxy, que autentica por IAM (Workload Identity) através da
      # Cloud SQL Admin API, e não passa pela lista de redes autorizadas —
      # é a "conexão autorizada" exigida no lugar de VPC peering completo.
    }
  }
}

resource "google_sql_database" "homolog" {
  name     = "oficina_homolog"
  instance = google_sql_database_instance.oficina.name
}

resource "google_sql_database" "producao" {
  name     = "oficina_producao"
  instance = google_sql_database_instance.oficina.name
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "google_sql_user" "app" {
  name     = var.db_user
  instance = google_sql_database_instance.oficina.name
  password = random_password.db_password.result
}

# ──────────────────────────────────────────
# Secret Manager — credenciais do banco
# ──────────────────────────────────────────
resource "google_secret_manager_secret" "db_password" {
  secret_id = "oficina-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "db_url_homolog" {
  secret_id = "oficina-db-url-homolog"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_url_homolog" {
  secret      = google_secret_manager_secret.db_url_homolog.id
  secret_data = "jdbc:postgresql://${google_sql_database_instance.oficina.public_ip_address}:5432/${google_sql_database.homolog.name}"
}

resource "google_secret_manager_secret" "db_url_producao" {
  secret_id = "oficina-db-url-producao"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_url_producao" {
  secret      = google_secret_manager_secret.db_url_producao.id
  secret_data = "jdbc:postgresql://${google_sql_database_instance.oficina.public_ip_address}:5432/${google_sql_database.producao.name}"
}

# ──────────────────────────────────────────
# Service Account dedicada para a aplicação (GKE) acessar o Cloud SQL
# via Cloud SQL Auth Proxy + Workload Identity (usado na Parte 2 - infra-k8s).
# ──────────────────────────────────────────
resource "google_service_account" "app_cloudsql" {
  account_id   = "oficina-app-cloudsql"
  display_name = "Oficina App - acesso ao Cloud SQL via Auth Proxy"
}

resource "google_project_iam_member" "app_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app_cloudsql.email}"
}

resource "google_secret_manager_secret_iam_member" "app_reads_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_cloudsql.email}"
}

# oficina-jwt-secret é criado manualmente (fora deste Terraform, ver runbook) e
# sobrevive a um terraform destroy — mas a service account abaixo não: ela é
# recriada do zero a cada apply, então essa concessão de acesso precisa estar
# aqui, e não só ter sido dada uma vez via `gcloud` manualmente (senão some na
# próxima recriação e quebra o deploy de oficina-auth-function, que lê esse
# secret para emitir um JWT compatível com o da aplicação principal).
resource "google_secret_manager_secret_iam_member" "app_reads_jwt_secret" {
  secret_id = "oficina-jwt-secret"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_cloudsql.email}"
}
