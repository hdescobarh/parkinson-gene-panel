export ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

IMAGE_NAME = parkinson-panel
LABEL = portfolio=parkinson-panel

.PHONY: setup validate-config check-dirs clean clean-docker

help:
	@echo "TODO: add help message"

build:
	@echo "[MAKE] Running development container..."
	docker build --target development -t $(IMAGE_NAME):dev \
		--label $(LABEL) \
		 . \
	docker build --target production -t $(IMAGE_NAME):prod \
		--label $(LABEL) \
		 . \

dev: validate-config check-dirs
	@echo "[MAKE] Running development container..."
	docker run --rm -it \
		--name $(IMAGE_NAME)-dev \
		-p 8888:8888 \
		-v $(ROOT_DIR)/makefile:/panel/src/makefile \
		-v $(ROOT_DIR)/config/:/panel/config/ \
		-v $(ROOT_DIR)/src:/panel/src \
		-v $(ROOT_DIR)/scripts:/panel/scripts \
		-v $(ROOT_DIR)/notebooks:/panel/notebooks \
		-v $(ROOT_DIR)/reports:/panel/reports \
		$(IMAGE_NAME):dev

setup: validate-config check-dirs
	"$(ROOT_DIR)/scripts/get_ncbi_refseq_files.sh"
	@echo "[MAKE] Production setup complete."

validate-config:
	@echo "[MAKE] Validating configuration..."
	@jq empty "$(ROOT_DIR)/config/config.json"

check-dirs:
	@echo "[MAKE] Ensuring directories exist..."
	@bash -c "source $(ROOT_DIR)/scripts/set_env.sh"

clean: validate-config
	@echo "[MAKE] Cleaning data..."
	@rm -rf $$(jq -r ".dir_paths.data.base_path" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] Cleaning reports..."
	@rm -rf $$(jq -r ".dir_paths.reports" "$(ROOT_DIR)/config/config.json")
	@echo "[MAKE] Cleaning logs..."
	@rm -rf $$(jq -r ".dir_paths.logging" "$(ROOT_DIR)/config/config.json")

clean-docker: validate-config
	@echo "[MAKE] Removing project images..."
	docker rmi $$(docker images --filter "label=$(LABEL)" -q)

