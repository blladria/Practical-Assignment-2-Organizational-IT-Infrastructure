terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Configuramos el proveedor para que hable con tu Minikube local
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# 1. ConfigMap
resource "kubernetes_config_map" "backend_config" {
  metadata {
    name = "backend-config"
  }
  data = {
    NODE_ENV = "production"
    PORT     = "3000"
  }
}

# 2. Service Backend (ClusterIP)
resource "kubernetes_service" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    selector = {
      app = "backend"
    }
    port {
      port        = 3000
      target_port = 3000
    }
    type = "ClusterIP"
  }
}

# 3. StatefulSet Backend
resource "kubernetes_stateful_set" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    service_name = "backend"
    replicas     = 1
    selector {
      match_labels = {
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend"
        }
      }
      spec {
        container {
          name  = "backend"
          image = "${var.dockerhub_user}/simple-app-gsx:${var.backend_tag}"
          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend_config.metadata[0].name
            }
          }
          volume_mount {
            name       = "backend-data"
            mount_path = "/data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "backend-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

# 4. Service Nginx (NodePort)
resource "kubernetes_service" "nginx_service" {
  metadata {
    name = "nginx-service"
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
      node_port   = 30080
    }
    type = "NodePort"
  }
}

# 5. Deployment Nginx
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "${var.dockerhub_user}/nginx-gsx:${var.nginx_tag}"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}