export ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: setup validate-config check-dirs get-annotations clean

setup: validate-config check-dirs get-annotations
	@echo "[MAKE]  Production setup complete."

validate-config:
	@echo "[MAKE] Validating configuration..."
	@jq empty "$(ROOT_DIR)/config/config.json"

check-dirs:
	@echo "[MAKE]  Ensuring directories exist..."
	@bash -c "source $(ROOT_DIR)/scripts/set_env.sh"

get-annotations:
	@"$(ROOT_DIR)/scripts/get_ncbi_refseq_files.sh"

clean: validate-config
	@echo "[MAKE]  Cleaning data..."
	@rm -rf $$(jq -r ".dir_paths.data.base_path" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE]  Cleaning reports..."
	@rm -rf $$(jq -r ".dir_paths.reports" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE]  Cleaning logs..."
	@rm -rf $$(jq -r ".dir_paths.logging" "$(ROOT_DIR)/config/config.json")
