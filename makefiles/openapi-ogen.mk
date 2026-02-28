# ---- Variables (defaults, можна перевизначити в головному Makefile) ----
OPENAPI_FILE ?= openapi/openapi.yml
API_DIR ?= gen/httpapi
PACKAGE ?= httpapi

# ogen binary
OGEN ?= $(shell which ogen 2>/dev/null || echo "$(HOME)/go/bin/ogen")

# =============================================================================
# OpenAPI (ogen)
# =============================================================================

.PHONY: openapi-generate
openapi-generate: _openapi-check-tools _openapi-clean-dir _openapi-gen _openapi-gen-helpers _openapi-gen-embed ## Generate Go API (types, server, client) from OpenAPI spec using ogen
	@printf "$(COLOR_GREEN)✓ Go API generation complete!$(COLOR_RESET)\n"
	@printf "$(COLOR_BLUE)  Generated files in $(API_DIR)/:$(COLOR_RESET)\n"
	@ls -la $(API_DIR)/*.go 2>/dev/null | awk '{print "    " $$NF}'

.PHONY: openapi-clean
openapi-clean: ## Remove generated Go API files
	@printf "$(COLOR_BLUE)→ Cleaning generated API files...$(COLOR_RESET)\n"
	@rm -rf $(API_DIR)
	@printf "$(COLOR_GREEN)✓ Cleaned $(API_DIR)/$(COLOR_RESET)\n"

.PHONY: openapi-install-tools
openapi-install-tools: ## Install OpenAPI tools (ogen, vacuum)
	@printf "$(COLOR_BLUE)→ Installing ogen...$(COLOR_RESET)\n"
	@go install github.com/ogen-go/ogen/cmd/ogen@latest
	@printf "$(COLOR_GREEN)✓ ogen installed$(COLOR_RESET)\n"
	@printf "$(COLOR_BLUE)→ Installing vacuum...$(COLOR_RESET)\n"
	@go install github.com/daveshanley/vacuum@latest
	@printf "$(COLOR_GREEN)✓ vacuum installed$(COLOR_RESET)\n"

# ---- Internal targets ----

.PHONY: _openapi-check-tools
_openapi-check-tools:
	@if ! command -v $(OGEN) >/dev/null 2>&1; then \
		printf "$(COLOR_RED)✗ ogen not found$(COLOR_RESET)\n"; \
		printf "$(COLOR_YELLOW)  Install: go install github.com/ogen-go/ogen/cmd/ogen@latest$(COLOR_RESET)\n"; \
		printf "$(COLOR_YELLOW)  Or run: make openapi-install-tools$(COLOR_RESET)\n"; \
		exit 1; \
	fi
	@printf "$(COLOR_GREEN)✓ ogen found: $(OGEN)$(COLOR_RESET)\n"
	@if ! command -v vacuum >/dev/null 2>&1; then \
		printf "$(COLOR_RED)✗ vacuum not found$(COLOR_RESET)\n"; \
		printf "$(COLOR_YELLOW)  Install: go install github.com/daveshanley/vacuum@latest$(COLOR_RESET)\n"; \
		printf "$(COLOR_YELLOW)  Or run: make openapi-install-tools$(COLOR_RESET)\n"; \
		exit 1; \
	fi
	@printf "$(COLOR_GREEN)✓ vacuum found$(COLOR_RESET)\n"

.PHONY: _openapi-clean-dir
_openapi-clean-dir:
	@printf "$(COLOR_BLUE)→ Cleaning generated Go API files...$(COLOR_RESET)\n"
	@rm -rf $(API_DIR)
	@mkdir -p $(API_DIR)

.PHONY: _openapi-gen
_openapi-gen:
	@printf "$(COLOR_BLUE)→ Generating Go code with ogen...$(COLOR_RESET)\n"
	@$(OGEN) -target $(API_DIR) -package $(PACKAGE) -clean -config ogen.yml $(OPENAPI_FILE)

.PHONY: _openapi-gen-helpers
_openapi-gen-helpers:
	@printf "$(COLOR_BLUE)→ Generating providers...$(COLOR_RESET)\n"
	@for tmpl in templates/*.go.tmpl; do \
		[ -f "$$tmpl" ] && cp "$$tmpl" "$(API_DIR)/$$(basename $$tmpl .go.tmpl).gen.go"; \
	done

.PHONY: _openapi-gen-embed
_openapi-gen-embed:
	@printf "$(COLOR_BLUE)→ Bundling and embedding OpenAPI spec...$(COLOR_RESET)\n"
	@cd $(dir $(OPENAPI_FILE)) && vacuum bundle $(notdir $(OPENAPI_FILE)) $(CURDIR)/$(API_DIR)/openapi.yml
	@printf "package $(PACKAGE)\n\nimport _ \"embed\"\n\n//go:embed openapi.yml\nvar OpenAPIDoc []byte\n" > $(CURDIR)/$(API_DIR)/openapi_embed.gen.go
