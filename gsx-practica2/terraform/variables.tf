variable "dockerhub_user" {
  description = "Usuario de Docker Hub"
  type        = string
}

variable "nginx_tag" {
  description = "Etiqueta (tag) de la imagen de Nginx"
  type        = string
  default     = "v1"
}

variable "backend_tag" {
  description = "Etiqueta (tag) de la imagen del Backend"
  type        = string
  default     = "v1"
}

variable "namespace" {
  description = "Entorno de despliegue (ej. dev, staging)"
  type        = string
}

variable "node_port" {
  description = "Puerto NodePort para Nginx (debe ser único por entorno)"
  type        = number
}

variable "nginx_replicas" {
  description = "Número de réplicas de Nginx"
  type        = number
  default     = 1
}