output "project_id" {
  description = "ID of the created GCP project"
  value       = module.app.project_id
}

output "project_number" {
  description = "Number of the created GCP project"
  value       = module.app.project_number
}

output "region" {
  description = "Region of Cloud Run and Artifact Registry"
  value       = module.app.region
}

output "service_urls" {
  description = "Public URL of every deployed service"
  value       = module.app.service_urls
}
