ALPINE_VERSION ?= 3.7

DOCKER_HUB ?= docker.io
DOCKER_IMAGE ?= mandrean/monorepo-tools

# Get the short commit hash & git remote URL
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))
GIT_REMOTE_URL ?= $(shell git config --get remote.origin.url)

CODE_VERSION ?= v7.0.0-alpha2

ifndef CODE_VERSION
$(error You need to specify the CODE_VERSION)
endif

# Find out if the working directory is clean
GIT_NOT_CLEAN_CHECK = $(shell git status --porcelain)
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
DOCKER_TAG_SUFFIX = -dirty
endif

# Fulfill the rules for releasing & deploying
# logical OR
ifneq ($(filter $(MAKECMDGOALS),release deploy),)
ifeq ($(ENVIRONMENT),prod)
# Don't deploy to production if this isn't a clean repo
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
$(error You are trying to release or deploy a build based on a dirty repo to production!)
endif
endif
endif

# Add the commit ref as a tag. Mark as dirty if the working directory isn't clean
DOCKER_TAG ?= $(CODE_VERSION)-$(GIT_COMMIT)$(DOCKER_TAG_SUFFIX)

# Aliases
.PHONY: all test login clean image push release lint chart publish deploy init plan apply checkmake shellcheck register
all: lint image chart
login: docker_login
clean: docker_clean
image: docker_build
push: docker_push
release: docker_release
lint: docker_lint makefile_lint shell_lint
checkmake: makefile_lint
shellcheck: shell_lint

# Clean up local Docker images
docker_clean:
	docker rmi -f $(shell docker images $(DOCKER_IMAGE) -q | uniq)

# Lint Docker image with Hadolint https://github.com/hadolint/hadolint
docker_lint:
	@docker run --rm -v "${PWD}:/home" $(DOCKER_HUB)/hadolint/hadolint:v1.6.6 hadolint --ignore DL3018 --ignore DL4001 /home/Dockerfile

# Build Docker image
# Build-time metadata as defined at http://label-schema.org & https://microbadger.com/labels
docker_build:
	docker build \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg VERSION=$(CODE_VERSION) \
		--build-arg VCS_URL=$(GIT_REMOTE_URL) \
		--build-arg VCS_REF=$(GIT_COMMIT) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		.

docker_tag:
	@echo $(DOCKER_TAG)

# Push Docker image
docker_push:
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

docker_release: docker_build docker_push
	# Also tag image latest and artifact version
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):$(CODE_VERSION)
	docker push $(DOCKER_IMAGE):latest
	docker push $(DOCKER_IMAGE):$(CODE_VERSION)

makefile_lint:
	@docker run --rm -v "${PWD}:/work" -w /work $(DOCKER_HUB)/mandrean/checkmake:28d3860 Makefile

shell_lint:
	@docker run -v "${PWD}:/mnt" -w /mnt --entrypoint "" $(DOCKER_HUB)/koalaman/shellcheck-alpine:v0.4.7 sh -c 'find . -name "*.sh" | xargs -r shellcheck'

.PHONY: docker_login docker_clean docker_lint docker_build docker_tag docker_push docker_release makefile_lint shell_lint
