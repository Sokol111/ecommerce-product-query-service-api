# ---- Config ----
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# ---- Variables ----
# Path to this repo's makefiles
MAKEFILES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))makefiles
PROJECT_NAME ?= $(shell basename $(CURDIR))
BUF ?= $(shell which buf 2>/dev/null || echo "$$$(go env GOPATH)/bin/buf")

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[36m
COLOR_RED := \033[31m

.DEFAULT_GOAL := help

# ---- Include makefiles ----
-include $(MAKEFILES_DIR)/protobuf-connect.mk
-include $(MAKEFILES_DIR)/connect-ts.mk

# =============================================================================
# Generate
# =============================================================================

.PHONY: generate
generate: lint connect-ts-generate connect-generate ## Generate all code (lint + Connect + TS)
	@printf "$(COLOR_GREEN)✓ All generation complete!$(COLOR_RESET)\n"

.PHONY: clean
clean: connect-ts-clean connect-clean ## Clean all generated files
	@printf "$(COLOR_GREEN)✓ All cleaned!$(COLOR_RESET)\n"

.PHONY: lint
lint: _connect-check-tools ## Lint proto files
	@printf "$(COLOR_BLUE)→ Linting proto files...$(COLOR_RESET)\n"
	$(BUF) lint
	@printf "$(COLOR_GREEN)✓ Proto linting passed$(COLOR_RESET)\n"

.PHONY: format
format: _connect-check-tools ## Format proto files
	@printf "$(COLOR_BLUE)→ Formatting proto files...$(COLOR_RESET)\n"
	$(BUF) format -w
	@printf "$(COLOR_GREEN)✓ Proto formatted$(COLOR_RESET)\n"

# =============================================================================
# Dependencies
# =============================================================================

.PHONY: tidy
tidy: ## Clean up go.mod and go.sum
	@printf "$(COLOR_GREEN)Tidying go.mod...$(COLOR_RESET)\n"
	go mod tidy

.PHONY: update-proto-deps
update-proto-deps: ## Update buf proto dependencies (buf.lock)
	@printf "$(COLOR_YELLOW)Updating buf proto dependencies...$(COLOR_RESET)\n"
	buf dep update
	@printf "$(COLOR_GREEN)✓ buf.lock updated$(COLOR_RESET)\n"

.PHONY: update-dependencies
update-dependencies: ## Update dependencies (patch versions only - safe)
	@printf "$(COLOR_YELLOW)Updating dependencies (patch only)...$(COLOR_RESET)\n"
	go get -u=patch ./...
	go mod tidy

.PHONY: update-dependencies-all
update-dependencies-all: ## Update ALL dependencies to latest (risky!)
	@printf "$(COLOR_YELLOW)⚠️  Updating ALL dependencies to latest versions...$(COLOR_RESET)\n"
	go get -u ./...
	go mod tidy

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show available commands
	@printf "\033[1m%s - Available targets:\033[0m\n\n" "$(PROJECT_NAME)"
	@awk 'BEGIN {FS = ":.*?## "; category = ""} \
		/^# =+$$/ {getline; if ($$0 ~ /^# /) {gsub(/^# /, "", $$0); gsub(/ *$$/, "", $$0); category = $$0}} \
		/^[a-zA-Z][a-zA-Z0-9-]+:.*?## / { \
			if (category != last_category) { \
				if (last_category != "") printf "\n"; \
				printf "\033[1;33m%s:\033[0m\n", category; \
				last_category = category \
			} \
			printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 \
		}' $(MAKEFILE_LIST)
	@echo ""
