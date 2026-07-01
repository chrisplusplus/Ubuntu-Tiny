#!/usr/bin/env bash
# Remove packages that were installed from the historical Ghostplant custom repo.
#
# This is intended to be run once inside an installed Ubuntu Tiny system after
# booting/installing an ISO that may have been built with the old custom APT
# source enabled. It prefers repository metadata when it is still present, then
# falls back to package names that were known to be installed from outside the
# Ubuntu archive in this repository's Dockerfiles.

set -euo pipefail

CUSTOM_REPO_REGEX='ppa\.launchpad\.net/ghostplant/flashback|ppa\.launchpad\.content\.net/ghostplant/flashback'
CUSTOM_SOURCE_GLOB='/etc/apt/sources.list.d/ghostplant-ubuntu-flashback*.list'
CUSTOM_KEY_GLOB='/etc/apt/trusted.gpg.d/ghostplant_ubuntu_flashback.gpg'

# Packages explicitly pulled from non-Ubuntu locations in older build recipes.
# Keep this fallback intentionally small: packages that also exist in Ubuntu
# should only be removed when apt metadata proves their installed version came
# from the custom repo.
FALLBACK_PACKAGES=(
  novnc-ex
  google-chrome-stable
)

DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<'USAGE'
Usage: sudo scripts/remove-custom-repo-packages.sh [--dry-run] [-y|--yes]

Find and purge packages installed from the historical Ghostplant custom APT repo,
then remove the repo source/key files.

Options:
  --dry-run   Print what would be removed without changing the system.
  -y, --yes   Pass -y to apt-get purge/autoremove.
  -h, --help  Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -y|--yes)
      ASSUME_YES=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ $EUID -ne 0 && $DRY_RUN -eq 0 ]]; then
  echo "This script must be run as root unless --dry-run is used." >&2
  exit 1
fi

apt_yes=()
if [[ $ASSUME_YES -eq 1 ]]; then
  apt_yes=(-y)
fi

is_installed() {
  dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null | grep -q '^ii '
}

installed_from_custom_repo() {
  local package=$1
  apt-cache policy "$package" 2>/dev/null | awk -v re="$CUSTOM_REPO_REGEX" '
    /^  Installed:/ { installed=$2 }
    $1 == "***" && $2 == installed { in_installed=1; next }
    in_installed && $0 ~ re { found=1 }
    in_installed && /^[[:space:]]{5}[0-9]+/ && $0 !~ re { next }
    END { exit found ? 0 : 1 }
  '
}

packages_from_cached_custom_lists() {
  shopt -s nullglob
  local list_file
  for list_file in /var/lib/apt/lists/*ppa.launchpad.net_ghostplant_flashback*_Packages \
                   /var/lib/apt/lists/*ppa.launchpad.content.net_ghostplant_flashback*_Packages; do
    awk '/^Package: / { print $2 }' "$list_file"
  done
  shopt -u nullglob
}

packages_to_purge=()
while IFS= read -r package; do
  [[ -n "$package" ]] || continue
  if is_installed "$package" && installed_from_custom_repo "$package"; then
    packages_to_purge+=("$package")
  fi
done < <(packages_from_cached_custom_lists | sort -u)

for package in "${FALLBACK_PACKAGES[@]}"; do
  if is_installed "$package"; then
    packages_to_purge+=("$package")
  fi
done

mapfile -t packages_to_purge < <(printf '%s\n' "${packages_to_purge[@]}" | awk 'NF' | sort -u)

if [[ ${#packages_to_purge[@]} -eq 0 ]]; then
  echo "No installed packages from the historical Ghostplant custom repo were found."
else
  echo "Packages selected for purge: ${packages_to_purge[*]}"
  if [[ $DRY_RUN -eq 1 ]]; then
    apt-get --simulate purge "${packages_to_purge[@]}"
  else
    apt-get purge "${apt_yes[@]}" "${packages_to_purge[@]}"
    apt-get autoremove --purge "${apt_yes[@]}"
  fi
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry run: would remove custom source/key files matching:"
  echo "  $CUSTOM_SOURCE_GLOB"
  echo "  $CUSTOM_KEY_GLOB"
else
  shopt -s nullglob
  rm -f $CUSTOM_SOURCE_GLOB $CUSTOM_KEY_GLOB
  shopt -u nullglob
  apt-get update
fi
