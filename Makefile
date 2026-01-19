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

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[36m
COLOR_RED := \033[31m

.DEFAULT_GOAL := help

# ---- Include makefiles ----
-include $(MAKEFILES_DIR)/openapi-ogen.mk
-include $(MAKEFILES_DIR)/openapi-ts.mk

# =============================================================================
# Generate
# =============================================================================

.PHONY: generate
generate: openapi-generate openapi-ts-generate ## Generate all code (OpenAPI Go + TS)
	@printf "$(COLOR_GREEN)✓ All generation complete!$(COLOR_RESET)\n"

.PHONY: clean
clean: openapi-clean openapi-ts-clean ## Clean all generated files
	@printf "$(COLOR_GREEN)✓ All cleaned!$(COLOR_RESET)\n"

# =============================================================================
# Setup
# =============================================================================

.PHONY: setup
setup: ## Setup local development (run once after clone)
	@printf "$(COLOR_BLUE)→ Ignoring local changes to go.mod...$(COLOR_RESET)\n"
	@git update-index --assume-unchanged go.mod
	@printf "$(COLOR_GREEN)✓ Setup complete$(COLOR_RESET)\n"

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
