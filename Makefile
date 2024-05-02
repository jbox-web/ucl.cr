# Ensure that every command in this Makefile
# will run with bash instead of the default sh
SHELL := /usr/bin/env bash

# Use sudo if current user is not root
UID := $(shell id -u)

ifneq ($(UID), 0)
	sudo = sudo
else
	sudo =
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

################
# Public tasks #
################

# This is the default task
all: help

setup: ## Setup local environment
	asdf plugin add crystal || true
	asdf install
	asdf current

ucl: ## Compile to development binary
	crystal build --threads 4 -o bin/ucl src/ucl.cr

ucl-release: ## Compile to production binary
	crystal build --threads 4 --release -o bin/ucl src/ucl.cr

deps: ## Install dependencies
	shards install

spec: ## Run Crystal spec
	export LD_LIBRARY_PATH=/usr/local/lib && crystal spec

clean: ## Cleanup environment
	rm -rf bin/*
	rm -rf lib/
	$(MAKE) deps

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

ameba: ## Run static code analysis
	bin/ameba

doc: ## Generate ucl.cr documentation
	rm -rf docs
	crystal doc
	open docs/index.html

.PHONY: all setup ucl ucl-release deps spec clean libucl libucl-build libucl-install ameba doc

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
