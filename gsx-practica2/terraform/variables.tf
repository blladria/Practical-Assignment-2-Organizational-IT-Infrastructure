variable "dockerhub_user" {
  description = "Tu usuario de Docker Hub"
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