export ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: help setup validate-config check-dirs clean-outputs

help:
	@echo "TODO: add help message"

setup: check-dirs
	"$(ROOT_DIR)/scripts/get_ncbi_refseq_files.sh"
	@echo "[MAKE] Environment setup complete."

check-dirs: validate-config
	@echo "[MAKE] Ensuring directories exist..."
	@bash -c "source $(ROOT_DIR)/scripts/set_env.sh"

validate-config:
	@echo "[MAKE] Validating configuration..."
	@jq empty "$(ROOT_DIR)/config/config.json"

clean-outputs: validate-config
	@echo "[MAKE] Cleaning data..."
	@rm -rf $$(jq -r ".dir_paths.data.base_path" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] Cleaning reports..."
	@rm -rf $$(jq -r ".dir_paths.reports" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] Cleaning logs..."
	@rm -rf $$(jq -r ".dir_paths.logging" "$(ROOT_DIR)/config/config.json")
