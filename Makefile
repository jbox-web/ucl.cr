# Ensure that every command in this Makefile
# will run with bash instead of the default sh
SHELL := /usr/bin/env bash

# Use sudo if current user is not root
UID := $(shell id -u)

SOURCE_FILE = src/ucl.cr
OUTPUT_FILE = bin/ucl

SPEC_OPTS            =
COMPILE_OPTS_DEV     = --threads 4
COMPILE_OPTS_RELEASE = --threads 4 --release --error-trace

ifneq ($(UID), 0)
	sudo = sudo
else
	sudo =
endif

ifeq ($(shell tty -s && echo true),true)
  SPEC_OPTS += --verbose
  COMPILE_OPTS_DEV += --progress
  COMPILE_OPTS_RELEASE += --progress
endif

ifeq ($(shell uname -s),Darwin)
	LIB_NAME = "libucl.dylib"
	LIB_NAME_VERSION = "libucl.7.dylib"
	LIB_RELOAD = true
else
	LIB_NAME = "libucl.so"
	LIB_NAME_VERSION = "libucl.so.7"
	LIB_RELOAD = $(sudo) ldconfig
endif

# This is the default task
all: help

.PHONY: all

#####################
# Development tasks #
#####################

setup: ## Setup local environment
	asdf plugin add crystal || true
	asdf install
	asdf current

ucl: ## Compile to development binary
	crystal build $(COMPILE_OPTS_DEV) -o $(OUTPUT_FILE) $(SOURCE_FILE)

ucl-release: ## Compile to production binary
	crystal build $(COMPILE_OPTS_RELEASE) -o $(OUTPUT_FILE) $(SOURCE_FILE)

deps: ## Install dependencies
	shards install

clean: ## Cleanup environment
	rm -rf bin/*
	rm -rf lib/

spec: ## Run Crystal spec
	export LD_LIBRARY_PATH=/usr/local/lib && crystal spec $(SPEC_OPTS)

doc: ## Generate ucl.cr documentation
	rm -rf docs
	crystal doc
	open docs/index.html

ameba: ## Run static code analysis
	bin/ameba

format: ## Format code
	crystal tool format src/

libucl: libucl-build libucl-install  ## Build and install vendored libucl lib

libucl-build: ## Build vendored libucl lib
	pushd ext/libucl && \
	./autogen.sh && \
	./configure && \
	make && \
	popd

libucl-install: ## Install vendored libucl lib
	$(sudo) cp -v ext/libucl/src/.libs/$(LIB_NAME_VERSION) /usr/local/lib/ && \
	$(sudo) ln -nfs /usr/local/lib/$(LIB_NAME_VERSION) /usr/local/lib/$(LIB_NAME) && \
	$(LIB_RELOAD)

.PHONY: setup ucl ucl-release deps clean spec doc ameba format libucl libucl-build libucl-install

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
