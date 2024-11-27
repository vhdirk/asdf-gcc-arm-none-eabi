#!/usr/bin/env bash

set -euo pipefail

TOOL_NAME="gcc-arm-none-eabi"
TOOL_TEST="arm-none-eabi-gcc --version"

BASE_URL="https://developer.arm.com"
URL="$BASE_URL/downloads/-/arm-gnu-toolchain-downloads"
LEGACY_URL="$BASE_URL/downloads/-/gnu-rm"

[ "${BASH_VERSINFO:-0}" -lt 4 ] && fail "requires bash v4 or higher"

curl_opts=(--progress-bar -fSL)

get_version() {
	local link=$1

	local part
	# we know of 3 different link structures
	if grep -q 'arm-gnu-toolchain' <<<"$link"; then
		part=$(echo "$link" | awk -F'arm-gnu-toolchain-' '{print $2}' | awk -F '?' '{print $1}')
	elif grep -q 'gcc-arm-none-eabi' <<<"$link"; then
		part=$(echo "$link" | awk -F'gcc-arm-none-eabi-' '{print $2}')
	else
		part=$(echo "$link" | awk -F'gcc-arm-' '{print $2}')
	fi

	local version_part
	version_part=$(echo "$part" | sed 's/\.tar\.\(xz\|bz2\)\|\.zip$//' | sed 's/-arm-none-eabi//')

	# cut of the platform/architecture
	echo "$version_part" | sed -E 's/-(x86_64|mingw|darwin|linux|win32|mac|aarch64).*$//'

}


all_links() {
  local arch
  local content
  local links
  local version

  arch=$(uname -m | tr '[:upper:]' '[:lower:]')

	content="$(curl -s "$URL")$(curl -s "$LEGACY_URL")"

	# Fetch the content of the URL and extract links
	links=$(echo "$content" | \
    awk -F 'href="' '/<a/{gsub(/".*/, "", $2); print $2}' | \
    grep -v "srcrel" | \
    awk '!/-src./' | \
    grep -E 'arm-none-eabi.*\.(tar.xz|tar.bz2|zip)\?' | \
    awk -F '?' '{print $1}' | \
    grep -v -i -E "mingw|darwin|win32|mac")

	declare -A versions=()

  while IFS= read -r link; do
    version=$(get_version "$link")

		if [[ "$OSTYPE" =~ darwin* && "$link" =~ (darwin|mac) ]]; then
			# filter mac links on mac
			if [[ $link =~ $arch ]]; then
				versions["$version"]="$link"
			elif [[ "$arch" == "arm64" && ! -v versions["$version"] ]]; then
				# The archs do not match. If we're on arm64, x86_64 is also usable
				# first test if there already is a matching link, if not, fill it in
				versions["$version"]="$link"
			fi
		elif [[ "$OSTYPE" =~ (cygwin|msys) && "$link" =~ (mingw|win32) ]]; then
			versions["$version"]="$link"
		elif [[ "$OSTYPE" =~ linux-gnu && ! "$link" =~ (mingw|darwin|win32|mac) ]]; then
			# if nothing matches, nothing matches :)
			if [[ "$link" =~ $arch ]]; then
				versions["$version"]="$link"
			elif [[ $arch == "x86_64" && ! "$link" =~ "aarch64" ]]; then
				versions["$version"]="$link"
			fi
		fi
	done <<<"$links"

  for version in "${!versions[@]}"; do
    echo "${BASE_URL}${versions[$version]}"
  done
}


fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' | LC_ALL=C sort -V | awk '{print $2}'
}

# ARM compilers are not semver. So we're just going to invent something here
arm_version_to_semver() {
  local version="$1"
  version=${version//[_-]/.}
  # shellcheck disable=SC2001
  version=$(echo "$version" | sed 's/\([0-9]\)\([a-zA-Z]\)/\1.\2/')
  version=${version//q/}
  version=${version//rel1/0}
  version=${version//bet1/0-beta1}

  if [[ "$version" =~ "mpacbti" ]]; then
    version="${version//mpacbti./}-mpacbti"
  fi
  cut -d'.' -f1-3 <<< "$version"
}

semver_to_arm_version() {
  local version="$1"
  #replace all dots wit globs, remove mpacbti string
  version="${version//./\*}"
  version="${version//-mpacbti/}"
  echo "$version"
}


# shellcheck disable=SC2120
list_all_versions() {
  local links
  local arch
  local version=""
  local semver=""
  local versions=()

  arch=$(uname -m | tr '[:upper:]' '[:lower:]')

  links=$(all_links "$arch")

  while IFS= read -r link; do
    version="$(get_version "$link")"
    semver="$(arm_version_to_semver "$version")"

    # shellcheck disable=SC2190
    versions+=( "$semver" )
  done <<<"$links"

  echo "${versions[@]}" | tr ' ' "\n" #| sort --version-sort
}

get_link() {
  local version="$1"
	local content
	local arch
	local links
  local link_version

  arch=$(uname -m | tr '[:upper:]' '[:lower:]')

  while IFS= read -r link; do
    link_version="$(get_version "$link")"
    semver="$(arm_version_to_semver "$link_version")"

    if [ "$semver" = "$version" ]; then
      echo "$link"
      return 0
    fi
  done <<<"$(all_links "$arch" )"
}


release_filename() {
	local version
	version="$1"

  local url
  url=$(get_link "${version}")

	basename "${url}"
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"

  url=$(get_link "${version}")

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

latest_release() {
	list_all_versions | sort --version-sort
}


install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi
	(
		mkdir -p "$install_path"

		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path/../"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
