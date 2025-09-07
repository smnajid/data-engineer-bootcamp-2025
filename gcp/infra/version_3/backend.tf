terraform {
  backend "gcs" {
    bucket = "tf-state-learn-de-zoomcamp-2025"
    prefix = "infra/dev/version_3"
  }
}
