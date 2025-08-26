export ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

SHELL := /bin/bash

VALID_ENVS := dev prod
ENV ?= dev

ifeq ($(filter $(ENV),$(VALID_ENVS)),)
$(error [MAKE] Invalid ENV value: $(ENV). Valid values are: $(VALID_ENVS))
endif

REQUIRED_TOOLS := python jq wget md5sum bedops
OPTIONAL_TOOLS := git

default: help
.PHONY: help deps init install-dev install-prod \
	prepare-workspace download-refseq \
	clean clean-outputs clean-envs clean-stamps

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

.stamps/:
	mkdir -p $@

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

.stamps/deps.stamp: | .stamps/
	$(MAKE) deps
	touch $@

## Initialize virtual environment and install dependencies (ENV=dev|prod).
init: .stamps/deps.stamp .venv-$(ENV)/.stamp

.venv-%/.stamp: pyproject.toml
	@if [ ! -f "$(dir $@)bin/activate" ]; then \
		echo "[MAKE] Creating .venv-$* Python virtual environment..."; \
		python -m venv $(dir $@); \
	else \
		echo "[MAKE] $* Python virtual environment .venv-$* already exists, skipping creation."; \
	fi
	$(MAKE) install-$*
	touch $@
	@echo "[MAKE] Python virtual environment .venv-$* properly configured."

install-dev:
	.venv-dev/bin/pip install --upgrade pip
	.venv-dev/bin/pip install -e .[dev]
	@if command -v git >/dev/null 2>&1; then \
		echo "[MAKE] Configuring nbdime for Git..."; \
		.venv-dev/bin/nbdime config-git --enable; \
	else \
		echo "[MAKE] Git not available, skipping nbdime configuration."; \
	fi

install-prod:
	.venv-prod/bin/pip install --upgrade pip
	.venv-prod/bin/pip install pip-tools
	# Lock dependencies in Python build environment for maximizing reproducibility.
	PIP_CONSTRAINT="$(ROOT_DIR)/requirements.txt" \
		.venv-prod/bin/pip-sync "$(ROOT_DIR)/requirements.txt"

.env.workspace: $(ROOT_DIR)/scripts/set_workspace.sh
	@echo "[MAKE] Setting up workspace..."
	@bash -c '\
		source $(ROOT_DIR)/scripts/set_workspace.sh && \
		awk "/^export [A-Z0-9_]+=/ { gsub(/^export /,\"\"); gsub(/=.*/,\"\"); print }" $(ROOT_DIR)/scripts/set_workspace.sh | \
		while read var; do echo "$$var=$${!var}"; done | \
		sort \
	' > .env.workspace

## Create required directories and setup workspace.
prepare-workspace: .env.workspace

.stamps/download-refseq.stamp: | .stamps/
	$(ROOT_DIR)/scripts/get_ncbi_refseq_files.sh
	@echo "[MAKE] NCBI RefSeq files downloaded."
	touch $@

## Download NCBI RefSeq reference genome files.
download-refseq: prepare-workspace .stamps/download-refseq.stamp

## Creates requirements.txt with locked dependency versions.
requirements.txt: $(ROOT_DIR)/pyproject.toml | .venv-dev/.stamp
	@echo "[MAKE] Creating requirements.txt..."
	.venv-dev/bin/pip-compile -o "$@" "$<"

## Remove all generated files, directories, and virtual environments.
clean: clean-outputs clean-envs clean-stamps

## Remove all outputs directories.
clean-outputs: config/config.json
	@echo "[MAKE] Cleaning data/ ..."
	@rm -rf $$(jq -r ".dir_paths.data.base_path" "$(ROOT_DIR)/config/config.json")
# data includes downloaded files
	@rm -rf .stamps/download-refseq.stamp
	@echo "[MAKE] Cleaning reports/ ..."
	@rm -rf $$(jq -r ".dir_paths.reports" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] Cleaning logs/ ..."
	@rm -rf $$(jq -r ".dir_paths.logging" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] cleaning workspace environment variables"
	@rm .env.workspace

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

clean-stamps:
	rm -rf .stamps/
