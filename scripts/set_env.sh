#!/usr/bin/env bash

: "${ROOT_DIR:?'Need to set ROOT_DIR before running this script.'}"

export LOGS_DIR="${ROOT_DIR%/}/logs"

# Load configuration

export CONFIG_FILE="${ROOT_DIR%/}/config/config.json"

NCBI_ACCESSION=$(jq -r '.reference_genome.ncbi_accession' "$CONFIG_FILE")
NCBI_NAME=$(jq -r '.reference_genome.ncbi_name' "$CONFIG_FILE")
export ASSEMBLY_TAG="${NCBI_ACCESSION}_${NCBI_NAME}"

DATA_BASE_PATH=$(jq -r '.dir_paths.data.base_path' "$CONFIG_FILE")
DATA_RAW=$(jq -r '.dir_paths.data.raw' "$CONFIG_FILE")
DATA_EXTERNAL=$(jq -r '.dir_paths.data.external' "$CONFIG_FILE")
DATA_INTERMEDIATE=$(jq -r '.dir_paths.data.intermediate' "$CONFIG_FILE")
DATA_PROCESSED=$(jq -r '.dir_paths.data.processed' "$CONFIG_FILE")
DATA_EXTERNAL=$(jq -r '.dir_paths.data.external' "$CONFIG_FILE")

NOTEBOOKS=$(jq -r '.dir_paths.notebooks' "$CONFIG_FILE")
REPORTS=$(jq -r '.dir_paths.reports' "$CONFIG_FILE")
FIGURES=$(jq -r '.dir_paths.figures' "$CONFIG_FILE")
TABLES=$(jq -r '.dir_paths.tables' "$CONFIG_FILE")

export RAW_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_RAW%/}"
export INTERMEDIATE_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_INTERMEDIATE%/}"
export PROCESSED_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_PROCESSED%/}"
export EXTERNAL_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_EXTERNAL%/}"

export NOTEBOOKS_DIR="${ROOT_DIR%/}/${NOTEBOOKS%/}"
export REPORTS_DIR="${ROOT_DIR%/}/${REPORTS%/}"
export FIGURES_DIR="${ROOT_DIR%/}/${FIGURES%/}"
export TABLES_DIR="${ROOT_DIR%/}/${TABLES%/}"

dirs=(
  "$LOGS_DIR"
	"$RAW_DATA_DIR"
	"$INTERMEDIATE_DATA_DIR"
	"$PROCESSED_DATA_DIR"
	"$EXTERNAL_DATA_DIR"
	"$NOTEBOOKS_DIR"
	"$REPORTS_DIR"
	"$FIGURES_DIR"
	"$TABLES_DIR"
)

# TODO: Add .env.tmp file for variables that need to be reused in other environments

for d in "${dirs[@]}"; do
	mkdir -p "$d"
done
