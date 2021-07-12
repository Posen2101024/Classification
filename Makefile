#!make
SHELL := /bin/bash

TIMESTAMP ?= $(shell date +%s)
NAMESPACE ?= classification
DEVICE    ?= 0

EXC_USER  := $(shell whoami)
BRANCH    := $(shell git rev-parse --abbrev-ref HEAD)
COMMIT    := $(shell git describe --always)

IMAGE     := $(EXC_USER)/$(NAMESPACE)/$(BRANCH):$(COMMIT)
CONTAINER := $(EXC_USER)_$(NAMESPACE)_$(COMMIT)_$(TIMESTAMP)

kill:
	@set -euo pipefail; \
	CONTAINER_ID=$$(docker ps -q -a -f "name=$(EXC_USER)_$(NAMESPACE)_$(COMMIT)_*"); \
	if [[ -n $$CONTAINER_ID ]]; then \
		docker stop $$CONTAINER_ID; \
		docker rm $$CONTAINER_ID; \
	fi;

clean: kill
	@set -euo pipefail; \
	IMAGE_ID=$$(docker images -q "$(IMAGE)"); \
	if [[ -n $$IMAGE_ID ]]; then \
		docker rmi -f $(IMAGE); \
	fi;

build: clean
	docker build --no-cache -t $(IMAGE) .

run:
	docker run -itd --name $(CONTAINER) $(IMAGE)
	-docker exec -it $(CONTAINER) /bin/bash

run-gpu:
	docker run --gpus '"device=$(DEVICE)"' -itd --name $(CONTAINER) $(IMAGE)
	-docker exec -it $(CONTAINER) /bin/bash

container-up: build run

container-up-gpu: build run-gpu
