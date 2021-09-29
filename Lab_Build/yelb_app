// Yelb App - Use this file to deploy Yelb app using Terraform Resources //
// To apply this file using terraform you must change file name to yelb_app.tf //

resource "kubernetes_namespace" "yelb_ns" {
  metadata {
    name = "yelb"
  }
}
resource "kubernetes_service" "yelb_redis_service" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "redis-server"
    namespace = "yelb"
    labels = {
      app = "redis-server"
      tier = "cache"
      environment = "cns_lab"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      port = "6379"
    }
    selector = {
      app = "redis-server"
      tier = "cache"
    }
  }
}
resource "kubernetes_service" "yelb_db_service" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "yelb-db"
    namespace = "yelb"
    labels = {
      app = "yelb-db"
      tier = "backenddb"
      environment = "cns_lab"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      port = "5432"
    }
    selector = {
      app = "yelb-db"
      tier = "backenddb"
    }
  }
}
resource "kubernetes_service" "yelb_appserver" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "yelb-appserver"
    namespace = "yelb"
    labels = {
      app = "yelb-appserver"
      tier = "middletier"
      environment = "cns_lab"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      port = "4567"
    }
    selector = {
      app = "yelb-appserver"
      tier = "middletier"
    }
  }
}
resource "kubernetes_service" "yelb_ui" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "yelb-ui"
    namespace = "yelb"
    labels = {
      app = "yelb-ui"
      tier = "frontend"
      environment = "cns_lab"
    }
  }
  spec {
    type = "NodePort"
    port {
      port = "80"
      protocol = "TCP"
      target_port = "80"
      node_port = "30001"
    }
    selector = {
      app = "yelb-ui"
      tier = "frontend"
    }
  }
}
resource "kubernetes_deployment" "yelb_ui" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "yelb-ui"
    namespace = "yelb"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "yelb-ui"
        tier = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "yelb-ui"
          tier = "frontend"
          environment = "cns_lab"
        }
      }
      spec {
        container {
          name = "yelb-ui"
          image = "mreferre/yelb-ui:0.7"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
resource "kubernetes_deployment" "redis_server" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "redis-server"
    namespace = "yelb"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redis-server"
        tier = "cache"
      }
    }
    template {
      metadata {
        labels = {
          app = "redis-server"
          tier = "cache"
          environment = "cns_lab"
        }
      }
      spec {
        container {
          name = "redis-server"
          image = "redis:4.0.2"
          port {
            container_port = 6379
          }
        }
      }
    }
  }
}
resource "kubernetes_deployment" "yelb_db" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "yelb-db"
    namespace = "yelb"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "yelb-db"
        tier = "backenddb"
      }
    }
    template {
      metadata {
        labels = {
          app = "yelb-db"
          tier = "backenddb"
          environment = "cns_lab"
        }
      }
      spec {
        container {
          name = "yelb-db"
          image = "mreferre/yelb-db:0.5"
          port {
            container_port = 5432
          }
        }
      }
    }
  }
}
resource "kubernetes_deployment" "yelb_appserver" {
  depends_on = [kubernetes_namespace.yelb_ns]
  metadata {
    name = "yelb-appserver"
    namespace = "yelb"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "yelb-appserver"
        tier = "middletier"
      }
    }
    template {
      metadata {
        labels = {
          app = "yelb-appserver"
          tier = "middletier"
          environment = "cns_lab"
        }
      }
      spec {
        container {
          name = "yelb-appserver"
          image = "mreferre/yelb-appserver:0.5"
          port {
            container_port = 4567
          }
        }
      }
    }
  }
}