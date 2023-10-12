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

libucl: ## Build vendored libucl lib
	pushd ext/libucl && \
	./autogen.sh && \
	./configure && \
	make && \
	$(sudo) cp -v src/.libs/libucl.so   /usr/local/lib/ && \
	$(sudo) cp -v src/.libs/libucl.so.5 /usr/local/lib/ && \
	$(sudo) ldconfig && \
	popd

ameba: ## Run static code analysis
	bin/ameba

.PHONY: all setup ucl ucl-release deps spec clean libucl ameba

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
