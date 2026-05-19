locals {
  name           = "gleb-dev"
  project_id     = "gleb-oops"
  project_number = "869233359603"
  region         = "us-east1"
  zone           = "us-east1-c"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
  provider "google" {
    region  = "${local.region}"
    project = "${local.project_id}"
  }
  EOF
}

remote_state {
  backend = "gcs"

  config = {
    bucket   = "tfstate-gleb-oops"
    location = local.region
    prefix   = path_relative_to_include()
    project  = local.project_id
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  location       = local.region
  project        = local.project_id
  project_id     = local.project_id
  project_number = local.project_number
  region         = local.region
  name           = local.name

  tags = {
    created-by      = "gleb"
    managed-by      = "terraform"
    terragrunt-path = path_relative_to_include()
  }
}
