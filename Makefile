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
REPO_NAME           ?= $(shell basename `pwd`)
BRANCH_NAME         ?= $(shell git rev-parse --abbrev-ref HEAD)
# GIT_ROOTDIR         = $(shell git rev-parse --show-toplevel)

# Manage automatically semver
GIT_LAST_TAG_COMMIT := $(shell git rev-list --abbrev-commit --tags --max-count=1)
GIT_LAST_TAG        := $(shell git describe --abbrev=0 --tags ${GIT_TAG_COMMIT} 2>/dev/null || true)
GIT_LAST_TAG_SEMVER := $(GIT_LAST_TAG:v%=%)
# check if the GIT_LAST_TAG_SEMVER string is empty (ergo: new repository)
ifeq ($(GIT_LAST_TAG_SEMVER),)
    GIT_LAST_TAG_SEMVER := 0.0.0
endif
GIT_LAST_TAG_SEMVER_MAJOR  := $(word 1,$(GIT_LAST_TAG_SEMVER))
GIT_LAST_TAG_SEMVER_MINOR  := $(word 2,$(GIT_LAST_TAG_SEMVER))
GIT_LAST_TAG_SEMVER_PATCH  := $(word 3,$(GIT_LAST_TAG_SEMVER))
# GIT_NEXT_TAG_SEMVER_MAJOR  := $(shell echo $$(($(GIT_LAST_TAG_SEMVER_MAJOR)+1)))
# GIT_NEXT_TAG_SEMVER_MINOR  := $(shell echo $$(($(GIT_LAST_TAG_SEMVER_MINOR)+1)))
# GIT_NEXT_TAG_SEMVER_PATCH   = $(shell echo $$(($(GIT_LAST_TAG_SEMVER_PATCH)+1)))

# Other (sometimes) useful variables
# env.REPO_REV_HASH ?= $(shell git rev-parse --short HEAD)
# env.DOCKER_TAG = BUILD_TAG.toLowerCase().replaceAll(/-|_|%/, "")

# Project specific variables - to edit in case of clone/fork
DOCKER_ACCOUNT_NAME := mattiaperi
DOCKER_REPO_NAME    := toolbox
DOCKER_REPOSITORY   := ${DOCKER_ACCOUNT_NAME}/${DOCKER_REPO_NAME}

ifdef TAG
  VERSION := ${TAG}
endif
DOCKER_TAG_VERS     := ${DOCKER_REPOSITORY}:${VERSION:v%=%} # Strip the "v" version prefix
DOCKER_TAG_LATEST   := ${DOCKER_REPOSITORY}:latest
ifneq ($(BRANCH_NAME),main)
DOCKER_TAG_VERS     := ${DOCKER_REPOSITORY}:${VERSION:v%=%}-SNAPSHOT # Strip the "v" version prefix and add -SNAPSHOT suffix
endif

#--- functions ---  


# ifndef TAG
#   $(info The TAG variable is missing, therefore is automatically calculated incrementing by 1 the TAG patch integer)
#   VERSION := ${GIT_NEXT_TAG_SEMVER_MAJOR}.${GIT_NEXT_TAG_SEMVER_MINOR}.${GIT_NEXT_TAG_SEMVER_PATCH}
# endif

# ifeq ($(BRANCH_NAME),main)
#   $(info The BRANCH_NAME variable is not main, therefore a -SNAPSHOT suffix is added)
#   VERSION := ${VERSION}-SNAPSHOT
# endif

# ifndef TAG
#   VERSION := ${GIT_NEXT_TAG_SEMVER_MAJOR}.${GIT_NEXT_TAG_SEMVER_MINOR}.${GIT_NEXT_TAG_SEMVER_PATCH}
# endif

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

#--- targets ---

all: help

help:  ## Display this help
	@echo '================================'
	@echo 'PREREQUISITES:                  '
	@echo '- docker                        '
	@echo '- docker hub account (optional) '
	@echo '- aws-cli (optional)            '
	@echo '================================'
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

git-push: ## Git push            (i.e. make git-push TAG="v0.0.7" GIT_COMMENT="Update README.md")
	bash -c '[[ -z `git status -s` ]]'
	git add .
	git commit -m "${GIT_COMMENT}"
	git tag -a "${VERSION}" -m "${GIT_COMMENT}"
	git push origin main --tags
	git tag -ln

docker-build: ## Docker image build  (i.e. make docker-build TAG="v0.0.7")
	docker build -t ${DOCKER_TAG_VERS} -t ${DOCKER_TAG_LATEST} -f Dockerfile .

docker-hub-login: ## Docker Hub login    (i.e. make login TAG="v0.0.7" DOCKER_ACCOUNT_NAME=username DOCKER_ACCOUNT_PASSWORD=password)
	$(info Make: Login to Docker Hub.)
	@docker login -u $(DOCKER_ACCOUNT_NAME) -p $(DOCKER_ACCOUNT_PASSWORD)

aws-ecr-login: ## AWS ECR login aws-cli
	$(eval AWS_ACCOUNT_ID=$(shell aws sts get-caller-identity --query Account --output text))
	aws ecr get-login-password --region $(AWS_CLI_REGION) | docker login --password-stdin --username AWS "$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_CLI_REGION).amazonaws.com"

docker-push: ## Docker image push   (i.e. make docker-push TAG="v0.0.7")
	$(info Make: Pushing "$(VERSION)" tagged image.)
	# ifeq ($(filter $(BRANCH_NAME),main master),)
	#   $(error The BRANCH_NAME is not main or master.)
	# endif
	docker push ${DOCKER_TAG_VERS}
	docker push ${DOCKER_TAG_LATEST}