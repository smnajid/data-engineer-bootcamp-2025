variable "project_id" {
  description = "Project hosting the state bucket"
  type        = string
}

variable "region" {
  description = "Default region for provider"
  type        = string
}

provider "google" {
  project = var.project_id
  region  = var.region
}


