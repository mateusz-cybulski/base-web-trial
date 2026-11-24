# The platform comes from base-web as a versioned module; `mise run platform` updates the ref.
# The project's own resources (e.g. an API key, a bucket) go in other files of this folder and
# reach the services through generated_secrets, extra_env and extra_services_to_enable.
module "app" {
  source = "git::https://github.com/mateusz-cybulski/base-web.git//terraform/app?ref=feat/terraform-module"

  repo_root = "${path.root}/../.."

  GITHUB_REPO_NAME          = var.GITHUB_REPO_NAME
  GCP_BILLING_ACCOUNT_ID    = var.GCP_BILLING_ACCOUNT_ID
  GCP_ORG_ID                = var.GCP_ORG_ID
  GCP_FOLDER_ID             = var.GCP_FOLDER_ID
  GCP_DNS_PROJECT_ID        = var.GCP_DNS_PROJECT_ID
  GCP_DNS_MANAGED_ZONE_NAME = var.GCP_DNS_MANAGED_ZONE_NAME
  DEVELOPERS                = var.DEVELOPERS
  DATABASE_URL              = var.DATABASE_URL
  DNS_BASE_DOMAIN           = var.DNS_BASE_DOMAIN
  GCP_SERVICES_TO_ENABLE    = var.GCP_SERVICES_TO_ENABLE
  GCP_REGION                = var.GCP_REGION
  IMAGE_TAG                 = var.IMAGE_TAG
}
