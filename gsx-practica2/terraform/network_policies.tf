# 1. POLÍTICA BASE: Default Deny All Ingress
# Bloquea absolutamente todo el tráfico entrante a todos los pods del namespace
# EXCEPTO el tráfico que venga de pods del mismo namespace.
resource "kubernetes_network_policy" "namespace_isolation" {
  metadata {
    name      = "namespace-isolation-policy"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  spec {
    pod_selector {} # Un selector vacío aplica a TODOS los pods del namespace

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = kubernetes_namespace.env_namespace.metadata[0].name
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

# 2. POLÍTICA DE EXCEPCIÓN: Permitir tráfico externo al Frontend (Nginx)
# Como la política anterior bloquea todo lo externo, abrimos un agujero 
# SÓLO para el Nginx para que los usuarios puedan acceder desde Internet.
resource "kubernetes_network_policy" "allow_external_to_frontend" {
  metadata {
    name      = "allow-external-to-frontend"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "nginx"
      }
    }

    ingress {
      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
