#!/usr/bin/env bash

ftp_download_file() {

	local ftp_file_path=$1
	local output_path=$2

	printf "[INFO] Starting download (%s)...\n" "$(basename "$ftp_file_path")"
	wget --continue --tries=5 --progress=dot:mega \
		"ftp://${ftp_file_path}" -O "${output_path}"

	if [ -f "$output_path" ]; then
		printf "[INFO] Download successful!\n"
		return 0
	else
		printf "[ERROR] Download failed!\n"
		return 1
	fi
}

validate_md5() {

	local expect=$1
	local file_path=$2
	local actual
	actual="$(md5sum "${file_path}" | awk '{print $1}')"

	printf "[INFO] Verifying file integrity (%s)...\n" "$(basename "$file_path")"
	if [ "$expect" = "$actual" ]; then
		printf "[INFO] MD5 checksum verification passed!\n"
		return 0
	else
		printf "[ERROR] MD5 checksum verification failed!\n"
		return 1
	fi
}
