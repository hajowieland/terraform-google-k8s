resource "random_id" "cluster_name" {
  count       = var.enable_google ? 1 : 0
  byte_length = 6
}

resource "random_id" "username" {
  count       = var.enable_google ? 1 : 0
  byte_length = 14
}

resource "random_id" "password" {
  count       = var.enable_google ? 1 : 0
  byte_length = 18
}

## Get your workstation external IPv4 address:
data "http" "workstation-external-ip" {
  count = var.enable_google ? 1 : 0
  url   = "http://ipv4.icanhazip.com"
}

locals {
  count                     = var.enable_google ? 1 : 0
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.0.body)}/32"
}

# Get available zones for Google Cloud region
data "google_compute_zones" "available" {
  count   = var.enable_google ? 1 : 0
  project = var.gcp_project
  region  = var.gcp_region
  status  = "UP"
}

# Get latest version available in the given zone
data "google_container_engine_versions" "current" {
  count    = var.enable_google ? 1 : 0
  project  = var.gcp_project
  location = data.google_compute_zones.available[count.index].names[0]
}

resource "google_container_cluster" "gke" {
  count              = var.enable_google ? 1 : 0
  name               = "${var.gke_name}-${random_id.cluster_name[count.index].hex}"
  location           = var.enable_regional_cluster ? var.gcp_region : data.google_compute_zones.available[count.index].names[0]
  project            = var.gcp_project
  min_master_version = data.google_container_engine_versions.current[count.index].latest_master_version
  node_version       = data.google_container_engine_versions.current[count.index].latest_master_version

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    service_account = var.gke_serviceaccount
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = true
    }
  }

  master_auth {
    username = random_id.username[count.index].hex
    password = random_id.password[count.index].hex

    client_certificate_config {
      issue_client_certificate = true
    }
  }

  # (Required for private cluster, optional otherwise) network (cidr) from which cluster is accessible
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "gke-admin"
      cidr_block   = local.workstation-external-cidr
    }
  }
}

resource "google_container_node_pool" "nodepool" {
  count      = var.enable_google ? 1 : 0
  project    = var.gcp_project
  name       = var.gke_pool_name
  location   = var.enable_regional_cluster ? var.gcp_region : data.google_compute_zones.available[count.index].names[0]
  cluster    = google_container_cluster.gke[count.index].name
  node_count = var.gke_nodes
  version    = data.google_container_engine_versions.current[count.index].latest_master_version

  node_config {
    preemptible     = var.gke_preemptible
    machine_type    = var.gke_node_type
    service_account = var.gke_serviceaccount

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = var.gke_oauth_scopes

    labels = {
      Project = "K8s"
    }

    tags = ["k8s"]
  }
}

data "template_file" "kubeconfig" {
  count    = var.enable_google ? 1 : 0
  template = file("${path.module}/gke_kubeconfig-template.yaml")

  vars = {
    cluster_name    = google_container_cluster.gke.0.name
    endpoint        = google_container_cluster.gke.0.endpoint
    user_name       = google_container_cluster.gke.0.master_auth.0.username
    user_password   = google_container_cluster.gke.0.master_auth.0.password
    cluster_ca      = google_container_cluster.gke.0.master_auth.0.cluster_ca_certificate
    client_cert     = google_container_cluster.gke.0.master_auth.0.client_certificate
    client_cert_key = google_container_cluster.gke.0.master_auth.0.client_key
  }
}

resource "local_file" "kubeconfiggke" {
  count    = var.enable_google ? 1 : 0
  content  = data.template_file.kubeconfig.0.rendered
  filename = "${path.module}/kubeconfig_gke"
}
