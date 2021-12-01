// Deploy Cisco Secure Analytics Daemonset //

// Secret //
resource "kubernetes_secret" "obsrvbl" {
  depends_on = []
  metadata {
    name = "obsrvbl"
  }

  data = {
    service_key = var.sca_service_key
  }
}

// Service Account //
resource "kubernetes_service_account" "obsrvbl" {
  depends_on = [kubernetes_secret.obsrvbl]
  metadata {
    name = "obsrvbl"
  }
}

// Cluster Role Binding //
resource "kubernetes_cluster_role_binding" "obsrvbl" {
  depends_on = [kubernetes_service_account.obsrvbl]
  metadata {
    name = "obsrvbl"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "view"
  }
  subject {
    kind = "ServiceAccount"
    name = "obsrvbl"
    namespace = "default"
  }
}

// DaemonSet //
resource "kubernetes_daemonset" "obsrvbl-ona" {
  depends_on = [kubernetes_cluster_role_binding.obsrvbl]
  metadata {
    name = "obsrvbl-ona"
  }
  spec {
    selector {
      match_labels = {
        name = "obsrvbl-ona"
      }
    }
    template {
      metadata {
        labels = {
          name = "obsrvbl-ona"
        }
      }
      spec {
        service_account_name = "obsrvbl"
        toleration {
          key = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
        host_network = true
        container {
          name = "ona"
          image = "obsrvbl/ona:4.2"
          env {
            name = "OBSRVBL_HOST"
            value = "https://sensor.ext.obsrvbl.com"
          }
          env {
            name = "OBSRVBL_SERVICE_KEY"
            value_from {
              secret_key_ref {
                name = "obsrvbl"
                key = "service_key"
              }
            }
          }
          env {
            name = "OBSRVBL_KUBERNETES_WATCHER"
            value = "true"
          }
          env {
            name = "OBSRVBL_HOSTNAME_RESOLVER"
            value = "false"
          }
          env {
            name = "OBSRVBL_NOTIFICATION_PUBLISHER"
            value = "false"
          }
          env {
            name = "OBSRVBL_POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
        }
      }
    }
  }
}