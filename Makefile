SERVICE_NAME := build_erlang
SERVICE_IMAGE_NAME ?= rbkmoney/build_erlang
DOCKER := docker
.PHONY: $(SERVICE_NAME) push clean
$(SERVICE_NAME): .state

COMMIT := $(shell git rev-parse HEAD)
rev = $(shell git rev-parse --abbrev-ref HEAD)
BRANCH := $(shell \
if [[ "${rev}" != "HEAD" ]]; then \
	echo "${rev}" ; \
elif [ -n "${BRANCH_NAME}" ]; then \
	echo "${BRANCH_NAME}"; \
else \
	echo `git name-rev --name-only HEAD`; \
fi)

.state:
	$(eval TAG := $(shell git rev-parse HEAD))
	$(DOCKER) build -t "$(SERVICE_IMAGE_NAME):$(TAG)" .
	echo $(TAG) > $@

push:
	$(DOCKER) push "$(SERVICE_IMAGE_NAME):$(shell cat .state)"

clean:
	test -f .state \
	&& $(DOCKER) rmi -f "$(SERVICE_IMAGE_NAME):$(shell cat .state)" \
	&& rm .state
