// Secure Workload Service Account //
resource "kubernetes_service_account" "tetration-read-only" {
  depends_on = []
  metadata {
    name = "tetration.read.only"
    namespace = "default"
  }
}
// Secure Workload ClusterRole //
resource "kubernetes_cluster_role" "tetration-read-only" {
  depends_on = [kubernetes_service_account.tetration-read-only]
  metadata {
    name = "tetration.read.only"
  }
  rule {
    api_groups = [
      ""
    ]
    resources = [
      "nodes",
      "services",
      "endpoints",
      "namespaces",
      "pods",
      "ingresses"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }
  rule {
    api_groups = [
      "extensions",
      "networking.k8s.io"
    ]
    resources = [
      "ingresses"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }
}
// Secure Workload Clusterrolebinding //
resource "kubernetes_cluster_role_binding" "tetration-read-only" {
  depends_on = [kubernetes_cluster_role.tetration-read-only]
  metadata {
    name = "tetration.read.only"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "tetration.read.only"
  }
  subject {
    kind = "ServiceAccount"
    name = "tetration.read.only"
    namespace = "default"
  }
}