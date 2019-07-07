terraform {
  backend "gcs" {
    bucket = "project-otus-201902-remote-state"
    prefix = "stage"
  }
}
