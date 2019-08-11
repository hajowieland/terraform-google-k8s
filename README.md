# Terraform Kubernetes on Google Cloud

This repository contains the Terraform module for creating a simple but ready-to-use Kubernetes Cluster on Google Cloud Kubernetes Engine (GKE).

It uses the latest available Kubernetes version available in the Google Cloud location and creates a kubeconfig file at completion.

#### Link to my comprehensive blog post (beginner friendly):
[https://napo.io/posts/terraform-kubernetes-multi-cloud-ack-aks-dok-eks-gke-oke/#google-cloud](https://napo.io/posts/terraform-kubernetes-multi-cloud-ack-aks-dok-eks-gke-oke/#google-cloud)


<p align="center">
<img alt="Google Cloud Logo" src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/61/Google_Cloud_Logo.svg/320px-Google_Cloud_Logo.svg.png">
</p>


- [Terraform Kubernetes on Google Cloud](#Terraform-Kubernetes-on-Google-Cloud)
- [Requirements](#Requirements)
- [Features](#Features)
- [Notes](#Notes)
- [Defaults](#Defaults)
- [Runtime](#Runtime)
- [Terraform Inputs](#Terraform-Inputs)
- [Outputs](#Outputs)


# Requirements

You need a [Google Cloud](https://cloud.google.com/free-trial/)  account with billing enabled (if you already exceeded the Trial).


# Features

* Always uses latest Kubernetes version available at Google Cloud location
* **kubeconfig** file generation
* Master nodes are available from workstation IP address only _(master_authorized_networks_config)_
* Create zonal (default) or regional GKE cluster (`enable_regional_cluster`)


# Notes

* `export KUBECONFIG=./kubeconfig_gke` in repo root dir to use the generated kubeconfig file
* If you want to create a regional cluster set `enable_regional_cluster` to **true** (keep in mind that number of `gke_nodes` will be deployed in every zone - e.g. 3 zones in a region * 2 gke_nodes => 6 worker nodes)
* The `enable_google` variable is used in the [hajowieland/terraform-kubernetes-multi-cloud](https://github.com/hajowieland/terraform-kubernetes-multi-cloud) module


# Defaults

See tables at the end for a comprehensive list of inputs and outputs.


* Default region: **europe-west3** _(Frankfurt, Germany)_
* Default node type: **n1-standard-2** _(1x vCPU, 7.5GB memory)_
* Default node pool size: **2**


# Runtime

`terraform apply`:

~5-6min

```
4.28s user
1.11s system
4:58.60 total
```

```
4.72s user
1.39s system
5:03.16 total
```

```
4.74s user
1.40s system
5:34.30 total
```


# Terraform Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| enable_google | Enable / Disable Google Cloud k8s | bool | true | yes |
| enable_regional_cluster | Create regional GKE cluster instead of zonal | bool | true | no |
| random_cluster_suffix | Random 6 byte hex suffix for cluster name | string |  | no |
| gcp_project | GCP Project ID | string |   | yes |
| gcp_region | GCP region | string | europe-west3 | no |
| gke_name | GKE cluster name | string | k8s | no |
| gke_pool_name | GKE node pool name | string | k8snodepool | no |
| gke_nodes | GKE Kubernetes worker nodes | number | 2 | no |
| gke_preemptible | Use GKE [preemptible](https://cloud.google.com/kubernetes-engine/docs/how-to/preemptible-vms) nodes | bool | false | no |
| gke_node_type | GKE node instance type | string | n1-standard-2 | no |
| gke_serviceaccount | GCP service account for GKE | string | default | no |
| gke_oauth_scopes | GCP [OAuth](https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes) scopes for GKE | list(string) | "https://www.googleapis.com/auth/compute", "https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring" | no |



# Outputs

| Name | Description |
|------|-------------|
| kubeconfig_path_gke | Kubernetes kubeconfig file |
| latest_k8s_master_version | Latest Kubernetes master Version available in Google Cloud location |

