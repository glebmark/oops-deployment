include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "https://github.com/terraform-google-modules/terraform-google-kubernetes-engine?ref=v41.0.2"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  name = "gleb-dev"

  # Zonal cluster = free management fee (vs $73/mo for regional)
  regional = false
  zones    = ["us-east1-c"]

  network           = dependency.network.outputs.network_name
  subnetwork        = dependency.network.outputs.subnets_names[0]
  ip_range_pods     = "primary-pods"
  ip_range_services = "primary-services"

  create_service_account               = true
  dns_cache                            = false
  enable_vertical_pod_autoscaling      = false
  filestore_csi_driver                 = false
  horizontal_pod_autoscaling           = false
  http_load_balancing                  = false
  logging_enabled_components           = ["SYSTEM_COMPONENTS"]
  monitoring_enable_managed_prometheus = false
  network_policy                       = false
  remove_default_node_pool             = true

  # Disable cluster autoscaler — fixed single node to minimize cost
  cluster_autoscaling = {
    auto_repair         = true
    auto_upgrade        = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    enabled             = false
    gpu_resources       = []
    max_cpu_cores       = 0
    max_memory_gb       = 0
    min_cpu_cores       = 0
    min_memory_gb       = 0
    max_surge           = 1
    max_unavailable     = 0
    strategy            = "SURGE"
  }

  node_pools = [
    {
      name                 = "spot-pool"
      machine_type         = "e2-medium"
      min_count            = 1
      max_count            = 1
      disk_size_gb         = 50
      disk_type            = "pd-standard"
      image_type           = "COS_CONTAINERD"
      enable_private_nodes = true
      auto_repair          = true
      auto_upgrade         = true
      # Spot VMs: ~60-91% cheaper, can be evicted (agent handles reconnect)
      spot                 = true
      enable_gcfs          = false
      enable_gvnic         = false
      local_ssd_count      = 0
      logging_variant      = "DEFAULT"
    },
  ]
}
