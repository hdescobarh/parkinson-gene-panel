#!/usr/bin/env bash

: "${ROOT_DIR:?'Need to set ROOT_DIR before running this script.'}"

# Load configuration

CONFIG_FILE="${ROOT_DIR%/}/config/config.json"
DATA_BASE_PATH=$(jq -r '.dir_paths.data.base_path' "$CONFIG_FILE")
DATA_RAW=$(jq -r '.dir_paths.data.raw' "$CONFIG_FILE")
DATA_EXTERNAL=$(jq -r '.dir_paths.data.external' "$CONFIG_FILE")

NCBI_ACCESSION=$(jq -r '.reference_genome.ncbi_accession' "$CONFIG_FILE")
NCBI_NAME=$(jq -r '.reference_genome.ncbi_name' "$CONFIG_FILE")

# Load configuration

export CONFIG_FILE="${ROOT_DIR%/}/config/config.json"

DATA_BASE_PATH=$(jq -r '.dir_paths.data.base_path' "$CONFIG_FILE")
DATA_RAW=$(jq -r '.dir_paths.data.raw' "$CONFIG_FILE")
DATA_EXTERNAL=$(jq -r '.dir_paths.data.external' "$CONFIG_FILE")
NCBI_ACCESSION=$(jq -r '.reference_genome.ncbi_accession' "$CONFIG_FILE")
NCBI_NAME=$(jq -r '.reference_genome.ncbi_name' "$CONFIG_FILE")

export RAW_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_RAW%/}"
export EXTERNAL_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_EXTERNAL%/}"
export ASSEMBLY_TAG="${NCBI_ACCESSION}_${NCBI_NAME}"
