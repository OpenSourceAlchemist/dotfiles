# Test harness Makefile
# Usage: make test, make shell, make clean

.PHONY: build test shell clean logs

CONTAINER_NAME := dotfiles-test
IMAGE_NAME := dotfiles-test:latest

build:
	@echo "Building test container..."
	podman build -t $(IMAGE_NAME) -f Dockerfile .

test: build
	@echo "Running test harness..."
	podman run --rm --name $(CONTAINER_NAME) $(IMAGE_NAME)

shell: build
	@echo "Opening shell in test container..."
	podman run -it --rm --name $(CONTAINER_NAME) $(IMAGE_NAME) /bin/bash

logs:
	podman logs $(CONTAINER_NAME)

clean:
	@echo "Cleaning up test artifacts..."
	podman rm -f $(CONTAINER_NAME) 2>/dev/null || true
	podman rmi $(IMAGE_NAME) 2>/dev/null || true
