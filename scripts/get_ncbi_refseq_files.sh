#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo >&2 "$0: Error on line $LINENO: $BASH_COMMAND"; exit $?' ERR

: "${ROOT_DIR:?'Need to set ROOT_DIR before running this script.'}"

# Initialize logging

exec > >(tee "${ROOT_DIR%/}/logs/${0%.*}") 2>&1
printf "[START] (%s)\n" "$(date)"

source "${ROOT_DIR%/}/scripts/utils.sh"

# Load configuration

CONFIG_FILE="${ROOT_DIR%/}/config/config.json"

DATA_BASE_PATH=$(jq -r '.dir_paths.data.base_path' "$CONFIG_FILE")
DATA_RAW=$(jq -r '.dir_paths.data.raw' "$CONFIG_FILE")
DATA_EXTERNAL=$(jq -r '.dir_paths.data.external' "$CONFIG_FILE")

NCBI_ACCESSION=$(jq -r '.reference_genome.ncbi_accession' "$CONFIG_FILE")
NCBI_NAME=$(jq -r '.reference_genome.ncbi_name' "$CONFIG_FILE")

mapfile -t FTP < <(
	jq -r \
		'.data_sources.ncbi_genomes_ftp | .site,
    .refseq_human_assemblies, .genomic_annotations_suffix,
    .assembly_report_suffix, .checksums,.uncompressed_checksums' "$CONFIG_FILE"
)

# TODO: Add a check for FTP length

# Generate derived variables

raw_data_dir="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_RAW%/}"
external_data_dir="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_EXTERNAL%/}"
assembly_tag="${NCBI_ACCESSION}_${NCBI_NAME}"
assembly_dir="${FTP[0]%/}/${FTP[1]%/}/${assembly_tag}"
annotations_filename="${assembly_tag}${FTP[2]}"
report_filename="${assembly_tag}${FTP[3]}"

local_annotations_path="${raw_data_dir}/${annotations_filename}"
local_report_path="${raw_data_dir}/${report_filename}"
local_checksum_path="${external_data_dir}/${FTP[4]}"
local_checksums_compressed_path="${external_data_dir}/${FTP[5]}"

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

printf "[SUCCESSFUL END] (%s)\n" "$(date)"
