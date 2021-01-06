.DEFAULT_GOAL := help
SHELL := /bin/bash
.PHONY: help

# import config
# configfile=.env
# include $(configfile)
# export $(shell sed 's/=.*//' $(configfile))


#--- commands and variables ---

# generate other variables. Keep in mind that here are variables, inside the targets the variable names become commands
#HOST_JENKINS_UID ?= $(shell id -u jenkins)
#HOST_JENKINS_GID ?= $(shell id -g jenkins)

# Used in order to have Makefile working locally, emulating Jenkins behavior
REPO_NAME ?= $(shell basename `pwd`)
BRANCH_NAME ?= $(shell git branch 2>/dev/null | grep '^*' | colrm 1 2)
#env.REPO_REV_HASH ?= $(shell git rev-parse --short HEAD)
#env.DOCKER_TAG = BUILD_TAG.toLowerCase().replaceAll(/-|_|%/, "")

DOCKER_ACCOUNT_NAME := mattiaperi
DOCKER_REPO_NAME    := toolbox
DOCKER_REPOSITORY   := ${DOCKER_ACCOUNT_NAME}/${DOCKER_REPO_NAME}'
DOCKER_TAG_VERS     := ${DOCKER_REPOSITORY}:${TAG}
DOCKER_TAG_LATEST   := ${DOCKER_REPOSITORY}:latest

# ifndef TAG
# $(error The TAG variable is missing.)
# endif

# HOW TO MANAGE DIFFERENT ENVIRONMENTS
# ifndef ENV
# $(error The ENV variable is missing.)
# endif
 
# ifeq ($(filter $(ENV),test dev stag prod),)
# $(error The ENV variable is invalid.)
# endif
 
# ifeq (,$(filter $(ENV),test dev))
# COMPOSE_FILE_PATH := -f docker-compose.yml
# endif

#--- functions ---


#--- targets ---

all: help

help:  ## Display this help
	@echo '====================='
	@echo 'PREREQUISITES:       '
	@echo '- docker             '
	@echo '====================='
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

git-push: ## Git push (i.e. make git-push TAG="v0.0.6" GIT_COMMENT="Update README.md")
	git add .
	git commit -m "${GIT_COMMENT}"
	git tag -a "${TAG}" -m "${GIT_COMMENT}"
	git push origin main --tags
	git tag -ln

docker-build: ## Docker image build (i.e. make docker-build TAG="v0.0.6")
	docker build -t ${DOCKER_TAG_VERS} -t ${DOCKER_TAG_LATEST} -f Dockerfile .

docker-hub-login: ## Docker Hub login
	$(info Make: Login to Docker Hub.)
	@docker login -u $(DOCKER_ACCOUNT_NAME) -p $(DOCKER_ACCOUNT_PASSWORD)

docker-push: ## Docker image push (i.e. make docker-push TAG="v0.0.6")
	$(info Make: Pushing "$(TAG)" tagged image.)
	docker login
	docker push ${DOCKER_TAG_VERS}
	docker push ${DOCKER_TAG_LATEST}