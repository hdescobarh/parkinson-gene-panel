export ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

VALID_ENVS := dev prod
ENV ?= dev

ifeq ($(filter $(ENV),$(VALID_ENVS)),)
$(error [MAKE] Invalid ENV value: $(ENV). Valid values are: $(VALID_ENVS))
endif

REQUIRED_TOOLS := python jq
OPTIONAL_TOOLS := git

default: help
.PHONY: help deps init install-dev install-prod \
	prepare-workspace download-refseq  \
	clean clean-outputs clean-envs

## This help screen.
help:
	@awk 'BEGIN { printf "Available targets:\n" } \
		/^#/ { comment = substr($$0, 3) } \
		/^[a-zA-Z0-9%._-]+:/ { \
			gsub(/:.*/, "", $$1); \
			if (comment) { \
				printf "  \033[32m%-18s\033[0m %s\n", $$1, comment; \
			} \
			comment = ""; \
		} \
		!/^#/ && !/^[a-zA-Z0-9%._-]+:/ { comment = "" }' $(MAKEFILE_LIST)

## Check required and optional system dependencies.
deps:
	@echo "[MAKE] Checking required dependencies..."
	@for tool in $(REQUIRED_TOOLS); do \
		if command -v $$tool >/dev/null 2>&1; then \
			echo "	✓ $$tool found."; \
		else \
			echo "	✗ $$tool not found (required)."; \
			exit 1; \
		fi; \
	done
	@echo "[MAKE] Checking optional dependencies..."
	@for tool in $(OPTIONAL_TOOLS); do \
		if command -v $$tool >/dev/null 2>&1; then \
			echo "	✓ $$tool found."; \
		else \
			echo "	✗ $$tool not found (optional)."; \
		fi; \
	done

## Initialize virtual environment and install dependencies (ENV=dev|prod).
init: deps .venv-$(ENV)/.stamp

.venv-%/.stamp: pyproject.toml
	@if [ ! -f "$(dir $@)bin/activate" ]; then \
		echo "[MAKE] Creating $* Python virtual environment..."; \
		python -m venv $(dir $@); \
	else \
		echo "[MAKE] $* Python virtual environment already exists, skipping creation."; \
	fi
	$(MAKE) install-$*
	touch $@
	@echo "[MAKE] Virtual environment $* properly configured."

install-dev:
	.venv-dev/bin/pip install --upgrade pip
	.venv-dev/bin/pip install -e .[dev]
	@if command -v git >/dev/null 2>&1; then \
		echo "[MAKE] Configuring nbdime for Git..."
		.venv-dev/bin/nbdime config-git --enable; \
	else \
		echo "[MAKE] Git not available, skipping nbdime configuration."; \
	fi

install-prod: requirements.txt
	.venv-prod/bin/pip install --upgrade pip
	.venv-prod/bin/pip install pip-tools
	PIP_CONSTRAINT="$(ROOT_DIR)/requirements.txt" \
		.venv-prod/bin/pip-sync "$(ROOT_DIR)/requirements.txt"

requirements.txt: $(ROOT_DIR)/pyproject.toml .venv-dev/.stamp
	@echo "[MAKE] Creating requirements.txt..."
	.venv-dev/bin/pip-compile -o "$@" "$<"

## Create required directories and setup workspace.
prepare-workspace: config/config.json
	@echo "[MAKE] Creating required directories..."
	@bash -c "source $(ROOT_DIR)/scripts/set_env.sh"

.stamps/:
	mkdir -p $@

.stamps/download-refseq.stamp: prepare-workspace | .stamps/
	"$(ROOT_DIR)/scripts/get_ncbi_refseq_files.sh"
	@echo "[MAKE] NCBI RefSeq files downloaded."
	touch $@

## Download NCBI RefSeq reference genome files.
download-refseq:.stamps/download-refseq.stamp

## Remove all generated files, directories, and virtual environments.
clean: clean-outputs clean-envs

## Remove all outputs directories.
clean-outputs: config/config.json
	@echo "[MAKE] Cleaning data/ ..."
	@rm -rf $$(jq -r ".dir_paths.data.base_path" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] Cleaning reports/ ..."
	@rm -rf $$(jq -r ".dir_paths.reports" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] Cleaning logs/ ..."
	@rm -rf $$(jq -r ".dir_paths.logging" "$(ROOT_DIR)/config/config.json")

## Remove all Python virtual environments.
clean-envs:
	@echo "[MAKE] Removing virtual environments..."
	@for env in $(VALID_ENVS); do \
		if [ -d ".venv-$$env" ]; then \
			echo "	Removing .venv-$$env/"; \
			rm -rf ".venv-$$env"; \
		else \
			echo "	.venv-$$env/ not found, skipping."; \
		fi; \
	done
