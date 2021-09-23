resource "kubectl_manifest" "sw_clusterrolebinding" {
  depends_on = []
  yaml_body = <<YAML
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tetration.read.only
  namespace: default

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tetration.read.only
rules:
  -
    apiGroups:
      - ""
    resources:
      - nodes
      - services
      - endpoints
      - namespaces
      - pods
      - ingresses
    verbs:
      - get
      - list
      - watch
  -
    apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tetration.read.only
roleRef:
  kind: ClusterRole
  name: tetration.read.only
  apiGroup: rbac.authorization.k8s.io
subjects:
  -
    kind: ServiceAccount
    name: tetration.read.only
    namespace: default
YAML
}
data "kubernetes_service_account" "tetration_read_only" {
  metadata {
    name = "tetration.read.only"
  }
}
data "kubernetes_secret" "tetration_read_only_name" {
  metadata {
    name = data.kubernetes_service_account.tetration_read_only.default_secret_name
  }
}
output "tetration_read_only_secret_token" {
  value = data.kubernetes_secret.tetration_read_only_name.data.token
  sensitive = true
}
