output "kubeconfig_path" {
  description = "Ruta local del kubeconfig generado"
  value       = local.kubeconfig_path
  sensitive   = true
}

output "api_server_url" {
  description = "Endpoint público del API Server"
  value       = "https://${local.api_server_addr}:6443"
}
