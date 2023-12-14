#!/usr/bin/env bash

set -euo pipefail

TOOL_NAME="gcc-arm-none-eabi"
TOOL_TEST="arm-none-eabi-c++ --version"

BASE_URL="https://developer.arm.com"
URL="$BASE_URL/downloads/-/arm-gnu-toolchain-downloads"
LEGACY_URL="$BASE_URL/downloads/-/gnu-rm"

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

get_links() {
	local content
	local arch
	local kernel
	local links
	content=$1

	# Get the system architecture and kernel
	arch=$(uname -m | tr '[:upper:]' '[:lower:]')
	kernel=$(uname -s | tr '[:upper:]' '[:lower:]')

	# Fetch the content of the URL and extract links
	links=$(echo "$content" | awk -F 'href="' '/<a/{gsub(/".*/, "", $2); print $2}' | grep -v "srcrel" | awk '!/-src./' | grep -E 'arm-none-eabi.*\.(tar.xz|tar.bz2|zip)\?' | awk -F '?' '{print $1}')

	declare -A versions

	while IFS= read -r link; do

		local version
		version=$(get_version "$link")

		# filter mac links on mac
		if [[ $kernel == "darwin" && "$link" =~ (darwin|mac) ]]; then

			if [[ $link =~ $arch ]]; then
				versions["$version"]=$BASE_URL$link
				continue
			elif [[ "$arch" == "arm64" && ! -v versions["$version"] ]]; then
				# The archs do not match. If we're on arm64, x86_64 is also usable
				# first test if there already is a matching link, if not, fill it in
				versions["$version"]=$BASE_URL$link
			fi
			# if nothing matches, nothing matches :)
		elif [[ $kernel == "linux" && ! "$link" =~ (mingw|darwin|win32|mac) ]]; then
			if [[ "$link" =~ $arch ]]; then
				versions[$version]=$BASE_URL$link
			elif [[ $arch == "x86_64" && ! "$link" =~ "aarch64" ]]; then
				versions[$version]=$BASE_URL$link
			fi
		fi
	done <<<"$links"

	declare -p versions
}

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' | LC_ALL=C sort -Vr | awk '{print $2}'
}

list_all_versions() {
	local content
	content="$(curl -s "$URL")$(curl -s "$LEGACY_URL")"
	local result
	result=$(get_links "$content")
	eval "$result"

	printf "%s\n" "${!versions[@]}"
}

release_filename() {
	local content
	content="$(curl -s "$URL")$(curl -s "$LEGACY_URL")"
	local result
	result=$(get_links "$content")
	eval "$result"

	local version
	version="$1"
	basename "${versions["$version"]}"
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"

	local content
	content="$(curl -s "$URL")$(curl -s "$LEGACY_URL")"
	local result
	result=$(get_links "$content")
	eval "$result"

	url=${versions["$version"]}

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

latest_release() {
	list_all_versions | sort_versions | head -n1 | xargs echo
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
