// Secure Workload Configuration Terraform Resources //
// To apply this file using terraform you must change file name to secure_workload.tf //

// Cluster Scope
resource "tetration_scope" "scope" {
  short_name          = local.eks_cluster_name
  short_query_type    = "eq"
  short_query_field   = "user_orchestrator_system/cluster_name"
  short_query_value   = local.eks_cluster_name
  parent_app_scope_id = "605bacee755f027875a0eef3"
}

// Yelb App Scope
resource "tetration_scope" "yelb_app_scope" {
  short_name          = "Yelb"
  short_query_type    = "eq"
  short_query_field   = "user_orchestrator_system/namespace"
  short_query_value   = "yelb"
  parent_app_scope_id = tetration_scope.scope.id
}

// Yelb App Filters
resource "tetration_filter" "yelb-db-srv" {
  name         = "${local.eks_cluster_name} Yelb DB Service"
  query        = <<EOF
                    {
                      "type": "eq",
                      "field": "user_orchestrator_system/service_name",
                      "value": "yelb-db"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = false
}
resource "tetration_filter" "yelb-db-pod" {
  name         = "${local.eks_cluster_name} Yelb DB Pod"
  query        = <<EOF
                    {
                      "type": "contains",
                      "field": "user_orchestrator_system/pod_name",
                      "value": "yelb-db"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = false
}
resource "tetration_filter" "yelb-ui-srv" {
  name         = "${local.eks_cluster_name} Yelb UI Service"
  query        = <<EOF
                    {
                      "type": "eq",
                      "field": "user_orchestrator_system/service_name",
                      "value": "yelb-ui"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = true
}
resource "tetration_filter" "yelb-ui-pod" {
  name         = "${local.eks_cluster_name} Yelb UI Pod"
  query        = <<EOF
                    {
                      "type": "contains",
                      "field": "user_orchestrator_system/pod_name",
                      "value": "yelb-ui"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = true
}
resource "tetration_filter" "yelb-app-srv" {
  name         = "${local.eks_cluster_name} Yelb App Service"
  query        = <<EOF
                    {
                      "type": "eq",
                      "field": "user_orchestrator_system/service_name",
                      "value": "yelb-appserver"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = false
}
resource "tetration_filter" "yelb-app-pod" {
  name         = "${local.eks_cluster_name} Yelb App Pod"
  query        = <<EOF
                    {
                      "type": "contains",
                      "field": "user_orchestrator_system/pod_name",
                      "value": "yelb-appserver"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = false
}
resource "tetration_filter" "yelb-redis-srv" {
  name         = "${local.eks_cluster_name} Yelb Redis Service"
  query        = <<EOF
                    {
                      "type": "eq",
                      "field": "user_orchestrator_system/service_name",
                      "value": "redis-server"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = false
}
resource "tetration_filter" "yelb-redis-pod" {
  name         = "${local.eks_cluster_name} Yelb Redis Pod"
  query        = <<EOF
                    {
                      "type": "contains",
                      "field": "user_orchestrator_system/pod_name",
                      "value": "redis-server"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = false
}
resource "tetration_filter" "any-ipv4" {
  name         = "${local.eks_cluster_name} Any IPv4"
  query        = <<EOF
                    {
                      "type": "subnet",
                      "field": "ip",
                      "value": "0.0.0.0/0"
                    }
          EOF
  app_scope_id = tetration_scope.yelb_app_scope.id
  primary      = true
  public       = true
}

// Application

resource "tetration_application" "yelb_app" {
  app_scope_id = tetration_scope.yelb_app_scope.id
  name = "Yelb"
  description = "3-Tier App"
  alternate_query_mode = true
  strict_validation = true
  primary = false
  absolute_policy {
    consumer_filter_id = tetration_filter.any-ipv4.id
    provider_filter_id = tetration_filter.yelb-ui-srv.id
    action = "ALLOW"
    layer_4_network_policy {
      port_range = [80, 80]
      protocol = 6
    }
  }
  absolute_policy {
    consumer_filter_id = tetration_filter.yelb-ui-pod.id
    provider_filter_id = tetration_filter.yelb-app-srv.id
    action = "ALLOW"
    layer_4_network_policy {
      port_range = [
        4567,
        4567]
      protocol = 6
    }
  }
  absolute_policy {
    consumer_filter_id = tetration_filter.yelb-app-pod.id
    provider_filter_id = tetration_filter.yelb-db-srv.id
    action = "ALLOW"
    layer_4_network_policy {
      port_range = [5432,5432]
      protocol = 6
    }
  }
  absolute_policy {
    consumer_filter_id = tetration_filter.yelb-app-pod.id
    provider_filter_id = tetration_filter.yelb-db-srv.id
    action = "ALLOW"
    layer_4_network_policy {
      port_range = [5432,5432]
      protocol = 6
    }
  }
  absolute_policy {
    consumer_filter_id = tetration_filter.yelb-app-pod.id
    provider_filter_id = tetration_filter.yelb-redis-srv.id
    action = "ALLOW"
    layer_4_network_policy {
      port_range = [6379, 6379]
      protocol = 6
    }
  }
  catch_all_action = "ALLOW"
}