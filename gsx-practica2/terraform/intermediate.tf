# --- RBAC de solo lectura para desarrolladores ---

# Creamos una cuenta de servicio (un "usuario" para aplicaciones o personas)
resource "kubernetes_service_account" "developer_user" {
  metadata {
    name      = "developer-sa"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
}

# Definimos qué puede hacer: Solo ver (get, list, watch)
resource "kubernetes_role" "read_only_role" {
  metadata {
    name      = "read-only-role"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "pods/log"]
    verbs      = ["get", "list", "watch"]
  }
}

# Unimos al "usuario" con el "rol"
resource "kubernetes_role_binding" "dev_read_only_binding" {
  metadata {
    name      = "dev-read-only-binding"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.read_only_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.developer_user.metadata[0].name
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
}

# --- CONTROL DE RECURSOS ---

# El límite TOTAL del entorno (Namespace)
resource "kubernetes_resource_quota" "env_quota" {
  metadata {
    name      = "env-resource-quota"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  spec {
    hard = {
      cpu    = "2"      # Máximo 2 CPUs entre todos los pods
      memory = "2Gi"    # Máximo 2GB de RAM total
      pods   = "10"     # Máximo 10 pods
    }
  }
}

# Límites por defecto para cada Pod individual
resource "kubernetes_limit_range" "env_limits" {
  metadata {
    name      = "env-limit-range"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
}