.PHONY: clean compile test patchUpVersion image deploy_dev majorUpVersion minorUpVersion
#
# Module: Makefile
#
# Copyright(c) 2020, Ciena, Inc. All rights reserved.
#
PROJECT := password_generator
PACKAGE := devops
VENDOR := localhost
IMAGE_NAME := $(VENDOR)/$(FULL_PROJECT_NAME)
VERSION := $(shell node -p -e "require('./package.json').version")
BP_ENTERPRISE_UI_PORT := 80

#Docker env
DOCKERFILE := docker/bp_enterprise
DOCKER_IMAGE ?= $(VENDOR)/$(PACKAGE):$(VERSION)
DOCKER_RUN_ARGS ?= -ti --rm
DOCKER_CONTAINER ?= $(PACKAGE)_$(VERSION)
PASS_THROUGH_ENV := $(if $(EXTRA_ENV),$(shell python -c 'print "--env "," --env ".join("$(EXTRA_ENV)".split(";"))'))
DOCKER_RUN := docker run $(DOCKER_RUN_ARGS) $(PASS_THROUGH_ENV)
DOCKER_BUILD_EXTRA ?=
DOCKER_BUILD := docker build $(DOCKER_BUILD_EXTRA)
DOCKER_PUBLISH ?= -p $(BP_ENTERPRISE_UI_PORT):$(BP_ENTERPRISE_UI_PORT)

clean:
	rm -rf node_modules
	rm -rf dist
	rm -rf $(DOCKERFILE)/bpe-ui

install:
	npm run app-build

setup:
	npm run setup

test:
	npm run test

code-coverage:
	npm run code-coverage

lint-check:
	npm run lint-check

############################
# Docker commands
############################
image:
	make install
	cp -r dist/bpe-ui $(DOCKERFILE)
	$(DOCKER_BUILD) --no-cache -t $(DOCKER_IMAGE) $(DOCKERFILE)

docker_run:
	$(DOCKER_RUN) $(DOCKER_PUBLISH) $(DOCKER_RUN_ARGS) $(DOCKER_APP_ENV) --name $(DOCKER_CONTAINER) $(DOCKER_IMAGE)

docker_start:
	docker run -d $(DOCKER_PUBLISH) $(DOCKER_RUN_ARGS) $(DOCKER_APP_ENV) --name $(DOCKER_CONTAINER) $(DOCKER_IMAGE)

docker_stop:
	docker stop $(DOCKER_CONTAINER)

docker_restart: docker_stop docker_start

docker_enter:
	docker exec -ti $(DOCKER_CONTAINER) '/bin/sh'

dockerClean:
	rm -fr docker/solution/env
	docker rm -f $(shell docker ps -q -f status=exited) ; docker rmi -f $(shell docker images -f "dangling=true" -q)

push:
	docker tag $(DOCKER_IMAGE) account/$(PACKAGE):$(VERSION)
	docker push account/$(PACKAGE):$(VERSION)

deploy_dev:
	sed -i -r 's/image: .*/image: account:$(VERSION)/g' k8s/deployment.yaml
	kubectl apply -f k8s/service.yaml -n develop
	kubectl apply -f k8s/gateway-vs.yaml -n develop
	kubectl apply -f k8s/deployment.yaml -n develop
	git add k8s/deployment.yaml package.json
	git commit -m "upversioning deployment image to $(VERSION)"
	git pull
	git push
	git push --tags

patchUpVersion:
	npm version patch

minorUpVersion:
	npm version minor

majorUpVersion:
	npm version major

