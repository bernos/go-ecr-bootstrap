GIT_BRANCH     ?= $(shell git rev-parse --abbrev-ref HEAD)
VERSION         = $(shell ./.buildkite/scripts/calculate-version.sh)
DOCKER_REGISTRY = 987872074697.dkr.ecr.ap-southeast-2.amazonaws.com
DOCKER_IMAGE    = $(DOCKER_REGISTRY)/bmcmahon/go-docker-stencil

docker-build:
	docker build --tag $(DOCKER_IMAGE):$(VERSION) .

docker-push: ecr-upsert docker-build
	docker push $(DOCKER_IMAGE):$(VERSION)
ifeq ($(GIT_BRANCH), master)
	docker tag $(DOCKER_IMAGE):$(VERSION) $(DOCKER_IMAGE):latest
	docker push $(DOCKER_IMAGE):latest
endif

ecr-upsert:
	./.buildkite/scripts/ecr-upsert.sh $(DOCKER_IMAGE):$(VERSION)

gh-release:
./.buildkite/scripts/gh-release.sh $(VERSION)
