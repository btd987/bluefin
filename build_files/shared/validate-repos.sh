#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eou pipefail

echo "Validating enabled repositories..."

if [[ ! -d /etc/yum.repos.d ]]; then
    echo "Warning: /etc/yum.repos.d does not exist"
    exit 0
fi

if ! ENABLED_REPO_IDS="$(LC_ALL=C dnf5 --quiet repo list --enabled | awk 'NR > 1 {print $1}')"; then
    echo "VALIDATION FAILED: unable to query enabled repositories"
    exit 1
fi

ENABLED_REPOS=()
while IFS= read -r repo; do
    [[ -n "$repo" ]] && ENABLED_REPOS+=("$repo")
done <<< "$ENABLED_REPO_IDS"
UNEXPECTED_REPOS=()

for repo in "${ENABLED_REPOS[@]}"; do
    case "$repo" in
        fedora | updates | updates-archive)
            ;;
        updates-testing)
            if [[ "${UBLUE_IMAGE_TAG:-stable}" != "beta" ]]; then
                UNEXPECTED_REPOS+=("$repo")
            fi
            ;;
        *)
            UNEXPECTED_REPOS+=("$repo")
            ;;
    esac
done

if [[ ${#UNEXPECTED_REPOS[@]} -gt 0 ]]; then
    echo "VALIDATION FAILED: unexpected repositories are enabled:"
    printf '  - %s\n' "${UNEXPECTED_REPOS[@]}"
    exit 1
fi

echo "Enabled repositories match the Fedora allowlist."
echo "::endgroup::"
