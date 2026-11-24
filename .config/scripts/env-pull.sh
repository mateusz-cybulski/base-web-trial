#!/usr/bin/env bash
#
# Fill each component's local .env with the secrets it may use locally, from the project's
# Secret Manager, with your own gcloud credentials (access is granted in IAM, never by a file
# sent around). Only the secrets a component lists in "local_secrets" of its service.json are
# pulled: production-only ones, such as DATABASE_URL, never reach a laptop.
#
# Usage (through mise):
#   mise run env              write src/<name>/.env for every component that lists local secrets
#   mise run env --dry-run    only show which variables would be written, read no secret
#
# The project is the one Terraform created for this repository (its name is the repository
# name); set GCP_PROJECT to use another one. Values are never printed. Other lines of an
# existing .env stay as they are; the pulled variables are replaced.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

dry_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=true ;;
    *) echo "Usage: mise run env [--dry-run]" >&2; exit 1 ;;
  esac
  shift
done

# "<component> <ENV_NAME> <secret id>" for every local secret of every component.
wanted="$(
  python3 - <<'PYTHON'
import json
import pathlib
import sys

for path in sorted(pathlib.Path("src").glob("*/service.json")):
    config = json.loads(path.read_text())
    secrets = config.get("secrets", {})
    for env_name in config.get("local_secrets", []):
        if env_name not in secrets:
            sys.exit(f"{path}: local_secrets names {env_name}, which is not in its secrets")
        print(path.parent.name, env_name, secrets[env_name])
PYTHON
)"

if [[ -z "$wanted" ]]; then
  echo "No component lists local_secrets in its service.json: nothing to pull."
  exit 0
fi

if $dry_run; then
  echo "Would write:"
  while read -r component env_name secret_id; do
    echo "  src/$component/.env  $env_name  (secret $secret_id)"
  done <<<"$wanted"
  exit 0
fi

project="${GCP_PROJECT:-}"
if [[ -z "$project" ]]; then
  repo="$(basename "$(git remote get-url origin 2>/dev/null || echo "$REPO_ROOT")" .git)"
  project="$(gcloud projects list --filter="name=$repo AND lifecycleState=ACTIVE" --format="value(projectId)")"
  if [[ "$(wc -w <<<"$project")" -ne 1 ]]; then
    echo "Could not find exactly one active project named '$repo' (found: ${project:-none})." >&2
    echo "Has the first deploy run? Set GCP_PROJECT=<project id> to choose one." >&2
    exit 1
  fi
fi
echo "Project: $project"

# The list comes in on descriptor 3: gcloud may ask for a password on standard input.
while read -r component env_name secret_id <&3; do
  env_file="src/$component/.env"
  # Never write a secret where a commit could pick it up.
  if ! git check-ignore -q "$env_file"; then
    echo "$env_file is not ignored by git; add .env to .gitignore first." >&2
    exit 1
  fi
  if ! value="$(gcloud secrets versions access latest --secret="$secret_id" --project="$project")"; then
    echo "Cannot read secret $secret_id. Your Google account (or a group it belongs to) must be" >&2
    echo "in the DEVELOPERS GitHub secret, and Terraform must have run since it was added." >&2
    exit 1
  fi
  touch "$env_file"
  chmod 600 "$env_file"
  # Replace the variable's line, keep everything else; the value goes through the environment,
  # not the command line, so it never shows in a process list.
  ENV_NAME="$env_name" ENV_VALUE="$value" python3 - "$env_file" <<'PYTHON'
import os
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
name, value = os.environ["ENV_NAME"], os.environ["ENV_VALUE"]
lines = [line for line in path.read_text().splitlines() if not line.startswith(f"{name}=")]
path.write_text("\n".join([*lines, f"{name}={value}"]) + "\n")
PYTHON
  echo "  $env_file  $env_name"
done 3<<<"$wanted"

echo "Done. Restart mise run dev: containers read .env when they start."
