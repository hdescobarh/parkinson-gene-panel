#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo >&2 "$0: Error on line $LINENO: $BASH_COMMAND"; exit $?' ERR

: "${ROOT_DIR:?'Need to set ROOT_DIR before running this script.'}"

source "${ROOT_DIR%/}/scripts/utils.sh"

# #### Load and parse configuration ####

# Send to stderr to avoid problems when capturing environment from Python
printf "[INFO] Parsing configuration...\n" >&2

export CONFIG_FILE="${ROOT_DIR%/}/config/config.json"

NCBI_ACCESSION=$(get_config  '.reference_genome.ncbi_accession')
NCBI_NAME=$(get_config  '.reference_genome.ncbi_name')
export ASSEMBLY_TAG="${NCBI_ACCESSION}_${NCBI_NAME}"

LOGGING=$(get_config  '.dir_paths.logging')
export LOGS_DIR="${ROOT_DIR%/}/${LOGGING}"

DATA_BASE_PATH=$(get_config  '.dir_paths.data.base_path')
DATA_RAW=$(get_config  '.dir_paths.data.raw')
DATA_EXTERNAL=$(get_config  '.dir_paths.data.external')
DATA_INTERMEDIATE=$(get_config  '.dir_paths.data.intermediate')
DATA_PROCESSED=$(get_config  '.dir_paths.data.processed')
DATA_EXTERNAL=$(get_config  '.dir_paths.data.external')

export RAW_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_RAW%/}"
export INTERMEDIATE_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_INTERMEDIATE%/}"
export PROCESSED_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_PROCESSED%/}"
export EXTERNAL_DATA_DIR="${ROOT_DIR%/}/${DATA_BASE_PATH%/}/${DATA_EXTERNAL%/}"

NOTEBOOKS=$(get_config  '.dir_paths.notebooks')
REPORTS=$(get_config  '.dir_paths.reports')
FIGURES=$(get_config  '.dir_paths.figures')
TABLES=$(get_config  '.dir_paths.tables')

export NOTEBOOKS_DIR="${ROOT_DIR%/}/${NOTEBOOKS%/}"
export REPORTS_DIR="${ROOT_DIR%/}/${REPORTS%/}"
export FIGURES_DIR="${ROOT_DIR%/}/${FIGURES%/}"
export TABLES_DIR="${ROOT_DIR%/}/${TABLES%/}"

# #### Ensure directories exist ####

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

printf "[INFO] Creating directories..\n" >&2
for d in "${dirs[@]}"; do
	mkdir -p "$d"
done
