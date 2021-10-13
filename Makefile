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

# Other (sometimes) useful variables
# env.REPO_REV_HASH ?= $(shell git rev-parse --short HEAD)
# env.DOCKER_TAG = BUILD_TAG.toLowerCase().replaceAll(/-|_|%/, "")

# Used in order to have Makefile working locally, emulating Jenkins behavior
# REPO_NAME           ?= $(shell basename `pwd`)
BRANCH_NAME         ?= $(shell git rev-parse --abbrev-ref HEAD)
# GIT_ROOTDIR         = $(shell git rev-parse --show-toplevel)

# Manage automatically semver
DATE                 = $(shell date +'%Y.%m.%d')
GIT_COMMENT_DEFAULT  = $(DATE) $(BRANCH_NAME)
GIT_LAST_TAG_COMMIT := $(shell git rev-list --abbrev-commit --tags --max-count=1)
GIT_LAST_TAG        := $(shell git describe --abbrev=0 --tags ${GIT_LAST_TAG_COMMIT} 2>/dev/null || true)
GIT_LAST_TAG_SEMVER := $(GIT_LAST_TAG:v%=%)
# check if the GIT_LAST_TAG_SEMVER string is empty (ergo: new repository)
ifeq ($(GIT_LAST_TAG_SEMVER),)
  GIT_LAST_TAG_SEMVER := 0.0.0
endif
GIT_LAST_TAG_SEMVER_NODOT  := $(subst ., ,$(GIT_LAST_TAG_SEMVER))
GIT_LAST_TAG_SEMVER_MAJOR  := $(word 1,$(GIT_LAST_TAG_SEMVER_NODOT))
GIT_LAST_TAG_SEMVER_MINOR  := $(word 2,$(GIT_LAST_TAG_SEMVER_NODOT))
GIT_LAST_TAG_SEMVER_PATCH  := $(word 3,$(GIT_LAST_TAG_SEMVER_NODOT))
# GIT_NEXT_TAG_SEMVER_MAJOR  := $(shell echo $$(($(GIT_LAST_TAG_SEMVER_MAJOR)+1)))
# GIT_NEXT_TAG_SEMVER_MINOR  := $(shell echo $$(($(GIT_LAST_TAG_SEMVER_MINOR)+1)))
GIT_NEXT_TAG_SEMVER_PATCH   = $(shell echo $$(($(GIT_LAST_TAG_SEMVER_PATCH)+1)))

# Project specific variables - to edit in case of clone/fork
DOCKER_ACCOUNT_NAME := mattiaperi
DOCKER_REPO_NAME    := toolbox
DOCKER_REPOSITORY   := ${DOCKER_ACCOUNT_NAME}/${DOCKER_REPO_NAME}

# Manage automatically docker tag version
ifdef TAG
  #$(info The TAG variable is passed as an argument.)
  VERSION := ${TAG}
endif
ifndef TAG
  #$(info The TAG variable is missing, therefore is automatically calculated incrementing by 1 the TAG patch integer)
  VERSION := v${GIT_LAST_TAG_SEMVER_MAJOR}.${GIT_LAST_TAG_SEMVER_MINOR}.${GIT_NEXT_TAG_SEMVER_PATCH}
endif

DOCKER_TAG_VERS     := ${DOCKER_REPOSITORY}:${VERSION:v%=%} # Strip the "v" version prefix
ifeq ($(BRANCH_NAME),main master)
DOCKER_TAG_VERS     := ${DOCKER_REPOSITORY}:${VERSION:v%=%}-SNAPSHOT # Strip the "v" version prefix and add -SNAPSHOT suffix
endif

DOCKER_TAG_LATEST   := ${DOCKER_REPOSITORY}:latest

# Manage automatically git commit message
ifdef COMMENT
  GIT_COMMENT := ${COMMENT}
endif
ifndef COMMENT
  GIT_COMMENT := ${GIT_COMMENT_DEFAULT}
endif

#--- functions ---  

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

debug:
	@echo "GIT_LAST_TAG_COMMIT=${GIT_LAST_TAG_COMMIT}"
	@echo "GIT_LAST_TAG=${GIT_LAST_TAG}"
	@echo "GIT_LAST_TAG_SEMVER=${GIT_LAST_TAG_SEMVER}"
	@echo "GIT_LAST_TAG_SEMVER_MAJOR=${GIT_LAST_TAG_SEMVER_MAJOR}"
	@echo "GIT_LAST_TAG_SEMVER_MINOR=${GIT_LAST_TAG_SEMVER_MINOR}"
	@echo "GIT_LAST_TAG_SEMVER_PATCH=${GIT_LAST_TAG_SEMVER_PATCH}"
	@echo "DOCKER_TAG_VERS=${DOCKER_TAG_VERS}"

help:  ## Display this help
	@echo '================================'
	@echo 'PREREQUISITES:                  '
	@echo '- docker                        '
	@echo '- go (optional)                 '	
	@echo '- docker hub account (optional) '
	@echo '- aws-cli (optional)            '
	@echo '================================'
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo '=============================================================='
	@echo 'WORKFLOW:                                                     '
	@echo '- make docker-build TAG="v0.0.21"                             '
	@echo '- make git-push TAG="v0.0.21" COMMENT="Add sudo package"      '
	@echo '- make docker-push TAG="v0.0.21"                              '
	@echo '=============================================================='

local-dev: ## Local development
	go run main.go

docker-build: ## Docker image build  (i.e. 'make docker-build' (TAG automatically added SEMVER_PATCH+1) or 'make docker-build TAG="v0.0.7"')
	$(info Make: Building docker image "$(VERSION)".)
	docker build -t $(DOCKER_TAG_VERS) -f Dockerfile .
	@[ "$(BRANCH_NAME)" == "main" ] && docker build -t $(DOCKER_TAG_LATEST) -f Dockerfile . || ( echo "$(BRANCH_NAME) is not "main" branch, skipping"; exit 0 )

docker-hub-login: ## Docker Hub login    (i.e. make login DOCKER_ACCOUNT_NAME=username DOCKER_TOKEN=token)
	$(info Make: Login to Docker Hub.)
	@docker login -u $(DOCKER_ACCOUNT_NAME) -p $(DOCKER_TOKEN)

aws-ecr-login: ## AWS ECR login aws-cli
	$(info Make: Login to AWS ECR.)
	$(eval AWS_ACCOUNT_ID=$(shell aws sts get-caller-identity --query Account --output text))
	aws ecr get-login-password --region $(AWS_DEFAULT_REGION) | docker login --password-stdin --username AWS "$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com"

git-push: ## Git push            (i.e. make git-push TAG="v0.0.7" COMMENT="Update README.md")
#bash -c '[[ -z `git status -s` ]]'
	git commit -am "${GIT_COMMENT}"
	git tag -a "${VERSION}" -m "${GIT_COMMENT}"
	git push origin main --tags
	git tag -ln

docker-push: ## Docker image push   (i.e. make docker-push TAG="v0.0.7")
	$(info Make: Pushing "$(VERSION)" tagged image.)
	docker push ${DOCKER_TAG_VERS}
	@[ "$(BRANCH_NAME)" == "main" ] && docker push ${DOCKER_TAG_LATEST} || ( echo "$(BRANCH_NAME) is not "main" branch, skipping"; exit 0 )

