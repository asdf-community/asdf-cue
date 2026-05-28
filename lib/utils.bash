#!/usr/bin/env bash

set -eo pipefail

CUE_REPO="cue-lang/cue"

curl_opts=(-fsSL)

fail() {
  echo -e "\e[31mFail:\e[m $*"
  exit 1
}

github_api() {
  local url="$1"
  local headers=(-H "Accept: application/vnd.github+json")

  if [ -n "${GITHUB_API_TOKEN:-}" ]; then
    headers+=(-H "Authorization: Bearer $GITHUB_API_TOKEN")
  elif [ -n "${GH_TOKEN:-}" ]; then
    headers+=(-H "Authorization: Bearer $GH_TOKEN")
  fi

  curl "${curl_opts[@]}" "${headers[@]}" "$url"
}

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_releases() {
  local page=1
  local response tags

  while [ "$page" -le 10 ]; do
    response=$(github_api "https://api.github.com/repos/${CUE_REPO}/releases?per_page=100&page=${page}")
    tags=$(printf "%s\n" "$response" | sed -n 's/^[[:space:]]*"tag_name": "v\{0,1\}\([^"]*\)",/\1/p')

    [ -n "$tags" ] || break
    printf "%s\n" "$tags"
    page=$((page + 1))
  done
}

list_all_versions() {
  list_github_releases
}

latest_stable_version() {
  local query="${1:-}"
  local latest=""

  while IFS= read -r version; do
    [ -z "$version" ] && continue
    [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    if [ -n "$query" ] && [ "${version#"$query"}" = "$version" ]; then
      continue
    fi
    latest="$version"
  done < <(list_all_versions | sort_versions)

  [ -n "$latest" ] || fail "No stable version found matching '${query}'"
  printf "%s\n" "$latest"
}

resolve_version() {
  local version="$1"

  case "$version" in
    latest)
      latest_stable_version
      ;;
    latest:*)
      latest_stable_version "${version#latest:}"
      ;;
    *)
      printf "%s\n" "$version"
      ;;
  esac
}

get_arch() {
  local arch=""

  case "$(uname -m)" in
    x86_64 | amd64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      fail "Arch '$(uname -m)' not supported!"
      ;;
  esac

  echo -n "$arch"
}

get_platform() {
  local platform=""

  case "$(uname | tr '[:upper:]' '[:lower:]')" in
    darwin) platform="darwin" ;;
    linux) platform="linux" ;;
    windows) platform="windows" ;;
    *)
      fail "Platform '$(uname -m)' not supported!"
      ;;
  esac

  echo -n "$platform"
}

archive_extension() {
  local platform="$1"

  case "$platform" in
    windows) echo -n "zip" ;;
    *) echo -n "tar.gz" ;;
  esac
}

release_json() {
  local version="$1"
  local response

  if ! response=$(github_api "https://api.github.com/repos/${CUE_REPO}/releases/tags/v${version}"); then
    return 1
  fi

  printf "%s\n" "$response"
}

asset_arch_pattern() {
  local arch="$1"

  case "$arch" in
    amd64) echo -n "amd64|x86_64" ;;
    *) echo -n "$arch" ;;
  esac
}

asset_urls() {
  sed -n 's/^[[:space:]]*"browser_download_url": "\([^"]*\)".*/\1/p'
}

select_asset_url() {
  local json="$1"
  local version="$2"
  local platform="$3"
  local arch="$4"
  local extension="$5"
  local version_pattern arch_pattern urls count

  # shellcheck disable=SC2016 # Keep the sed replacement literal.
  version_pattern=$(printf "%s" "$version" | sed 's/[.[\*^$()+?{}|]/\\&/g')
  arch_pattern=$(asset_arch_pattern "$arch")
  urls=$(
    printf "%s\n" "$json" |
      asset_urls |
      grep -Ei "/cue_v?${version_pattern}_" |
      grep -Ei "_${platform}_" |
      grep -Ei "_(${arch_pattern})\\.${extension}$" || true
  )

  [ -n "$urls" ] || return 1

  count=$(printf "%s\n" "$urls" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$count" -gt 1 ]; then
    echo "Unable to choose a single release asset:" >&2
    echo "$urls" >&2
    return 2
  fi

  printf "%s\n" "$urls"
}

download_url() {
  local version="$1"
  local platform="$2"
  local arch="$3"
  local extension="$4"
  local json url status

  if ! json=$(release_json "$version"); then
    fail "Could not fetch GitHub release metadata for cue ${version}. The version may not have downloadable release assets, or the GitHub API may be unavailable or rate-limited."
  fi

  status=0
  url=$(select_asset_url "$json" "$version" "$platform" "$arch" "$extension") || status=$?
  if [ "$status" -eq 2 ]; then
    fail "Found multiple release assets for cue ${version} (${platform}/${arch})"
  fi

  if [ -z "$url" ] && [ "$platform" = "darwin" ] && [ "$arch" = "arm64" ]; then
    status=0
    url=$(select_asset_url "$json" "$version" "$platform" "amd64" "$extension") || status=$?
    if [ "$status" -eq 2 ]; then
      fail "Found multiple release assets for cue ${version} (${platform}/amd64)"
    fi
    if [ -n "$url" ]; then
      echo "No darwin/arm64 asset found for cue ${version}; using darwin/amd64 asset. Rosetta 2 is required." >&2
    fi
  fi

  [ -n "$url" ] || fail "No downloadable release asset found for cue ${version} (${platform}/${arch})"
  printf "%s\n" "$url"
}
