SERVICE_NAME := build-erlang
ORG_NAME ?= rbkmoney
SERVICE_IMAGE_NAME ?= $(ORG_NAME)/build-erlang
DOCKER ?= docker
DOCKER_BUILD_OPTIONS ?=
.PHONY: $(SERVICE_NAME) push clean tag
$(SERVICE_NAME): .state

COMMIT := $(shell git rev-parse HEAD)
rev = $(shell git rev-parse --abbrev-ref HEAD)
BRANCH := $(shell \
if [ "${rev}" != "HEAD" ]; then \
	echo "${rev}" ; \
elif [ -n "${BRANCH_NAME}" ]; then \
	echo "${BRANCH_NAME}"; \
else \
	echo `git name-rev --name-only HEAD`; \
fi)

.state:
	$(eval TAG := $(shell git rev-parse HEAD))
	$(DOCKER) build -t "$(SERVICE_IMAGE_NAME):$(TAG)" $(DOCKER_BUILD_OPTIONS) .
	echo $(TAG) > $@

tag:
	$(if $(REGISTRY),,echo "REGISTRY is not set" ; exit 1)
	$(eval TAG := $(shell cat .state))
	$(DOCKER) tag "$(SERVICE_IMAGE_NAME):$(TAG)" "$(REGISTRY)/$(SERVICE_IMAGE_NAME):$(TAG)"

push: tag
	$(if $(REGISTRY),,echo "REGISTRY is not set" ; exit 1)
	$(eval TAG := $(shell cat .state))
	$(DOCKER) push "$(REGISTRY)/$(SERVICE_IMAGE_NAME):$(TAG)"

clean:
	$(if $(REGISTRY),,@echo "REGISTRY is not set" ; exit 1)
	test -f .state
	$(eval TAG := $(shell cat .state))
	$(DOCKER) rmi -f "$(REGISTRY)/$(SERVICE_IMAGE_NAME):$(TAG)" "$(SERVICE_IMAGE_NAME):$(TAG)" \
	&& rm .state
