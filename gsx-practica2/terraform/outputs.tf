output "nginx_node_port" {
  value       = kubernetes_service.nginx_service.spec[0].port[0].node_port
  description = "El puerto externo para acceder al Frontend"
}