include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "https://github.com/terraform-google-modules/terraform-google-cloud-router?ref=v8.0.0"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  name    = "gleb-dev-nat-router"
  nats    = [{ name = "gleb-dev-nat-gateway" }]
  network = dependency.network.outputs.network_name
}
