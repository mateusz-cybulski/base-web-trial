#!/usr/bin/env bash
#
# Update this project to a version of the platform (base-web): the Terraform module's ref and the
# files the platform owns. The project's own files (src/, its Terraform resources, compose
# includes, mise tasks it added) are never touched. Review the changes, then commit them.
#
# Usage (through mise):
#   mise run platform            the latest release tag (vX.Y.Z) of base-web
#   mise run platform v1.2.0     a given tag, or a branch to try an unreleased change
#   mise run platform --list     show the release tags
#
# Environment (set in mise.toml):
#   TEMPLATE_REPO   base-web's URL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"
# shellcheck source=lib/fetch-branch.sh
source .config/scripts/lib/fetch-branch.sh

# Owned by the platform: replaced as a whole on every update.
PLATFORM_FILES=(
  .config/scripts
  .config/terraform/versions.tf
  .config/terraform/variables.tf
  .config/terraform/outputs.tf
  .config/terraform/moved.tf
  .github/workflows/terraform.yml
)
MODULE_CALL=.config/terraform/main.tf
REF_FILE=.config/platform-ref

repo="${TEMPLATE_REPO:?TEMPLATE_REPO is not set (see [env] in mise.toml)}"

release_tags() {
  git ls-remote --tags --refs "$repo" 'v*' | sed 's#.*refs/tags/##' | sort -V
}

case "${1:-}" in
  --list) release_tags; exit 0 ;;
  "") ref="$(release_tags | tail -1)"; [[ -n "$ref" ]] || { echo "base-web has no release tag yet." >&2; exit 1; } ;;
  *) ref="$1" ;;
esac

fetch_branch "$repo" "$ref"

for path in "${PLATFORM_FILES[@]}"; do
  rm -rf "$path"
  mkdir -p "$(dirname "$path")"
  git -C "$FETCHED_DIR" archive FETCH_HEAD "$path" | tar -x -C "$REPO_ROOT"
done

# Only the module's ref changes in main.tf: the variables passed to it are the project's.
sed -i.bak -E "s#(base-web\.git//terraform/app\?ref=)[^\"]*#\1$ref#" "$MODULE_CALL" && rm "$MODULE_CALL.bak"
echo "$ref" >"$REF_FILE"

echo "Platform: $ref"
git status --short -- "${PLATFORM_FILES[@]}" "$MODULE_CALL" "$REF_FILE"
echo "Review with git diff, then commit. A new module input may need a value in $MODULE_CALL."
