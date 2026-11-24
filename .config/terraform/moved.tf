# Projects created before the platform became a module had these resources at the root. These
# blocks move them into module.app instead of destroying and recreating them (the project, its
# services, DNS records). For a new project they do nothing.

moved {
  from = random_string.project_suffix
  to   = module.app.random_string.project_suffix
}

moved {
  from = google_project.app_project
  to   = module.app.google_project.app_project
}

moved {
  from = google_project_service.app_services
  to   = module.app.google_project_service.app_services
}

moved {
  from = google_secret_manager_secret.managed
  to   = module.app.google_secret_manager_secret.managed
}

moved {
  from = google_secret_manager_secret_version.managed
  to   = module.app.google_secret_manager_secret_version.managed
}

moved {
  from = google_secret_manager_secret_iam_member.service
  to   = module.app.google_secret_manager_secret_iam_member.service
}

moved {
  from = google_secret_manager_secret_iam_member.developer
  to   = module.app.google_secret_manager_secret_iam_member.developer
}

moved {
  from = google_artifact_registry_repository.app
  to   = module.app.google_artifact_registry_repository.app
}

moved {
  from = google_service_account.service
  to   = module.app.google_service_account.service
}

moved {
  from = google_project_iam_member.service
  to   = module.app.google_project_iam_member.service
}

moved {
  from = docker_image.service
  to   = module.app.docker_image.service
}

moved {
  from = docker_registry_image.service
  to   = module.app.docker_registry_image.service
}

moved {
  from = google_cloud_run_v2_service.service
  to   = module.app.google_cloud_run_v2_service.service
}

moved {
  from = google_cloud_run_v2_service_iam_member.public
  to   = module.app.google_cloud_run_v2_service_iam_member.public
}

moved {
  from = google_cloud_run_domain_mapping.service
  to   = module.app.google_cloud_run_domain_mapping.service
}

moved {
  from = google_dns_record_set.service
  to   = module.app.google_dns_record_set.service
}
