#!/usr/bin/env bash
set -uo pipefail
trap 'echo >&2 "$0: Error on line $LINENO: $BASH_COMMAND"; exit $?' ERR

: "${ROOT_DIR:?'Need to set ROOT_DIR before running this script.'}"

FTP_ACCESSION_DIR="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/"
FTP_ANNOTATIONS_FILENAME="GCF_000001405.40_GRCh38.p14_genomic.gff.gz"
FTP_ANNOTATIONS_GZ_MD5_CHECKSUM="24b731562b9d4cae9e37b23404b5be16"
FTP_ANNOTATIONS_GFF_MD5_CHECKSUM="99c39a02df7339a96d57f5072a90c5a9"

# Defining variables and functions

outputFilePath="${ROOT_DIR%/}/data/external/${FTP_ANNOTATIONS_FILENAME}"
logFilePath="${ROOT_DIR%/}/logs/download_annotations.log"

mkdir -p "$(dirname "$outputFilePath")"
mkdir -p "$(dirname "$logFilePath")"

validate_md5() {
	local expect=$1
	local file=$2
	local actual
	actual="$(md5sum "${file}" | cut -d " " -f 1)"
	printf "[INFO] Verifying file integrity (%s)...\n" "$(basename "$file")"
	if [ "$expect" = "$actual" ]; then
		printf "[INFO] MD5 checksum verification passed!\n"
		return 0
	else
		printf "[ERROR] MD5 checksum verification failed!\n"
		return 1
	fi
}

# Initialize logging
exec > >(tee "$logFilePath") 2>&1
printf "[START] (%s)\n" "$(date)"


# Download from FTP server and check download integrity
printf "[INFO] Starting download...\n"

wget --continue --tries=5 \
	"${FTP_ACCESSION_DIR%/}/${FTP_ANNOTATIONS_FILENAME}" \
	-O "$outputFilePath" \
	--progress=dot:mega

if [ -f "$outputFilePath" ]; then
	printf "[INFO] Download successful! Verifying checksum...\n"
else
	printf "[ERROR] Download failed!\n"
	exit 1
fi

validate_md5 "$FTP_ANNOTATIONS_GZ_MD5_CHECKSUM" "$outputFilePath"

# Decompress and verify integrity
printf "[INFO] Decompressing (%s)...\n" "$(basename "$outputFilePath")"
gunzip --keep --force --verbose "$outputFilePath"

if validate_md5 "$FTP_ANNOTATIONS_GFF_MD5_CHECKSUM" "${outputFilePath%.*}"; then
	rm "$outputFilePath"
fi

printf "[SUCCESSFUL END]\n"
