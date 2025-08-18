export ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

IMAGE_NAME = parkinson-panel
LABEL = portfolio=parkinson-panel

.PHONY: help setup validate-config check-dirs clean-outputs \
	clean-docker dev-build dev-run dev-start

help:
	@echo "TODO: add help message"

dev-build:
	@echo "[MAKE] Running development container..."
docker build --target development -t $(IMAGE_NAME): dev \
		--label $(LABEL) .

dev-run: check-dir
	@echo "[MAKE] Running development container..."
	touch requirements.txt
# TODO: get the paths from config.json
	docker run --rm -it \
		--name $(IMAGE_NAME)-dev \
-p 8888: 8888 \
-v $(ROOT_DIR)/makefile: /panel/makefile \
-v $(ROOT_DIR)/config/: /panel/config/ \
-v $(ROOT_DIR)/src: /panel/src \
-v $(ROOT_DIR)/scripts: /panel/scripts \
-v $(ROOT_DIR)/notebooks: /panel/notebooks \
-v $(ROOT_DIR)/reports: /panel/reports \
-v $(ROOT_DIR)/logs: /panel/logs \
-v $(ROOT_DIR)/requirements.txt: /panel/requirements.txt \
$(IMAGE_NAME): dev /bin/bash

dev-start: setup
	@echo "[MAKE] Running development container..."
	tmux new-session -d -s jupyter \
		'jupyter lab --no-browser --allow-root \
		--notebook-dir=./notebooks --ip=0.0.0.0 --port=8888 \
		--ServerApp.token= --ServerApp.password= ./notebooks/'
	@echo "Development environment started. Jupyter at http://localhost:8888"

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

clean-docker: validate-config
	@echo "[MAKE] Removing project images..."
	docker rmi $$(docker images --filter "label=$(LABEL)" -q)
