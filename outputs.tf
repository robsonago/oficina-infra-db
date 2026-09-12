output "instance_connection_name" {
  description = "Connection name usado pelo Cloud SQL Auth Proxy (project:region:instance)"
  value       = google_sql_database_instance.oficina.connection_name
}

output "public_ip_address" {
  description = "IP público da instância (só acessível via Cloud SQL Auth Proxy/Admin API, sem rede autorizada aberta)"
  value       = google_sql_database_instance.oficina.public_ip_address
}

output "db_homolog_name" {
  value = google_sql_database.homolog.name
}

output "db_producao_name" {
  value = google_sql_database.producao.name
}

output "db_user" {
  value = google_sql_user.app.name
}

output "app_service_account_email" {
  description = "Service account que a aplicação (GKE) deve usar via Workload Identity"
  value       = google_service_account.app_cloudsql.email
}

output "secret_db_password_id" {
  value = google_secret_manager_secret.db_password.secret_id
}
