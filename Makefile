################
# Public tasks #
################

# This is the default task
all: help

ucl: ## Compile to development binary
	crystal build --threads 4 -o bin/ucl src/ucl.cr

ucl-release: ## Compile to production binary
	crystal build --threads 4 --release -o bin/ucl src/ucl.cr

deps: ## Install dependencies
	shards install

spec: ## Run Crystal spec
	crystal spec

clean: ## Cleanup environment
	rm -rf bin/*
	rm -rf lib/
	$(MAKE) deps

.PHONY: all ucl ucl-release deps spec clean

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
