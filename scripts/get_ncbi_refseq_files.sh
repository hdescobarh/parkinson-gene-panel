#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo >&2 "$0: Error on line $LINENO: $BASH_COMMAND"; exit $?' ERR

: "${ROOT_DIR:?'Need to set ROOT_DIR before running this script.'}"

source "${ROOT_DIR%/}/scripts/utils.sh"
source "${ROOT_DIR%/}/scripts/set_env.sh"

# Initialize logging

script_name=$(basename "$0")
exec > >(tee "${LOGS_DIR%/}/${script_name%.*}") 2>&1
printf "[DOWNLOADS] Start(%s)\n" "$(date)"

# Generate derived variables

mapfile -t FTP < <(
	get_config\
		'.data_sources.ncbi_genomes_ftp | .site,
    .refseq_human_assemblies, .genomic_annotations_suffix,
    .assembly_report_suffix, .checksums,.uncompressed_checksums'
)

# TODO: Need to validate non null for each FTP value

assembly_dir="${FTP[0]%/}/${FTP[1]%/}/${ASSEMBLY_TAG}"
annotations_filename="${ASSEMBLY_TAG}${FTP[2]}"
report_filename="${ASSEMBLY_TAG}${FTP[3]}"

local_annotations_path="${RAW_DATA_DIR}/${annotations_filename}"
local_report_path="${RAW_DATA_DIR}/${report_filename}"
local_checksum_path="${EXTERNAL_DATA_DIR}/${FTP[4]}"
local_checksums_compressed_path="${EXTERNAL_DATA_DIR}/${FTP[5]}"

# Download checksum files and get hash

ftp_download_file "${assembly_dir}/${FTP[4]}" "${local_checksum_path}"
compressed_md5=$(grep "./${annotations_filename}" "${local_checksum_path}" | awk '{print $1}')
ftp_download_file "${assembly_dir}/${FTP[5]}" "${local_checksums_compressed_path}"
uncompressed_md5=$(grep "./${annotations_filename%.*}" "${local_checksums_compressed_path}" | awk '{print $2}')

# Download assembly report and genome annotations

ftp_download_file "${assembly_dir}/${report_filename}" "${local_report_path}"
ftp_download_file "${assembly_dir}/${annotations_filename}" "${local_annotations_path}"

# Decompression and file integrity md5 checks

validate_md5 "${compressed_md5}" "${local_annotations_path}"

printf "[INFO] Decompressing (%s)...\n" "$(basename "${local_annotations_path}")"
gunzip --keep --force --verbose "${local_annotations_path}"
validate_md5 "${uncompressed_md5}" "${local_annotations_path%.*}"

printf "[DOWNLOADS] Successful end (%s)\n" "$(date)"
