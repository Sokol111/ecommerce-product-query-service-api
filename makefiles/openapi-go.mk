# ---- Variables (defaults, можна перевизначити в головному Makefile) ----
OPENAPI_FILE ?= openapi/openapi.yml
API_DIR ?= gen/httpapi
PACKAGE ?= httpapi

# oapi-codegen binary
OAPI_CODEGEN ?= $(shell which oapi-codegen 2>/dev/null || echo "$(HOME)/go/bin/oapi-codegen")

# =============================================================================
# OpenAPI
# =============================================================================

.PHONY: openapi-generate
openapi-generate: _openapi-check-tools _openapi-create-dir _openapi-gen-types _openapi-gen-server _openapi-gen-client _openapi-gen-embed ## Generate Go API (types, server, client) from OpenAPI spec
	@printf "$(COLOR_GREEN)✓ Go API generation complete!$(COLOR_RESET)\n"
	@printf "$(COLOR_BLUE)  Generated files in $(API_DIR)/:$(COLOR_RESET)\n"
	@ls -la $(API_DIR)/*.go 2>/dev/null | awk '{print "    " $$NF}'

.PHONY: openapi-clean
openapi-clean: ## Remove generated Go API files
	@printf "$(COLOR_BLUE)→ Cleaning generated API files...$(COLOR_RESET)\n"
	@rm -rf $(API_DIR)
	@printf "$(COLOR_GREEN)✓ Cleaned $(API_DIR)/$(COLOR_RESET)\n"

.PHONY: openapi-install-tools
openapi-install-tools: ## Install OpenAPI tools (oapi-codegen)
	@printf "$(COLOR_BLUE)→ Installing oapi-codegen...$(COLOR_RESET)\n"
	@go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest
	@printf "$(COLOR_GREEN)✓ oapi-codegen installed$(COLOR_RESET)\n"

# ---- Internal targets ----

.PHONY: _openapi-check-tools
_openapi-check-tools:
	@if ! command -v $(OAPI_CODEGEN) >/dev/null 2>&1; then \
		printf "$(COLOR_RED)✗ oapi-codegen not found$(COLOR_RESET)\n"; \
		printf "$(COLOR_YELLOW)  Install: go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest$(COLOR_RESET)\n"; \
		printf "$(COLOR_YELLOW)  Or run: make openapi-install-tools$(COLOR_RESET)\n"; \
		exit 1; \
	fi
	@printf "$(COLOR_GREEN)✓ oapi-codegen found: $(OAPI_CODEGEN)$(COLOR_RESET)\n"

.PHONY: _openapi-create-dir
_openapi-create-dir:
	@mkdir -p $(API_DIR)

.PHONY: _openapi-gen-types
_openapi-gen-types:
	@printf "$(COLOR_BLUE)→ Generating Go types (models)...$(COLOR_RESET)\n"
	@$(OAPI_CODEGEN) -generate types -package $(PACKAGE) -o $(API_DIR)/models.gen.go $(OPENAPI_FILE)

.PHONY: _openapi-gen-server
_openapi-gen-server:
	@printf "$(COLOR_BLUE)→ Generating Go server (gin-server, strict-server, spec)...$(COLOR_RESET)\n"
	@$(OAPI_CODEGEN) -generate gin-server,strict-server,spec -package $(PACKAGE) -o $(API_DIR)/server.gen.go $(OPENAPI_FILE)

.PHONY: _openapi-gen-client
_openapi-gen-client:
	@printf "$(COLOR_BLUE)→ Generating Go client...$(COLOR_RESET)\n"
	@$(OAPI_CODEGEN) -generate client -package $(PACKAGE) -o $(API_DIR)/client.gen.go $(OPENAPI_FILE)

.PHONY: _openapi-gen-embed
_openapi-gen-embed:
	@printf "$(COLOR_BLUE)→ Embedding OpenAPI spec...$(COLOR_RESET)\n"
	@cp $(OPENAPI_FILE) $(API_DIR)/openapi.yml
	@echo "package $(PACKAGE)" > $(API_DIR)/openapi.gen.go
	@echo "" >> $(API_DIR)/openapi.gen.go
	@echo "import _ \"embed\"" >> $(API_DIR)/openapi.gen.go
	@echo "" >> $(API_DIR)/openapi.gen.go
	@echo "//go:embed openapi.yml" >> $(API_DIR)/openapi.gen.go
	@echo "var OpenAPIDoc []byte" >> $(API_DIR)/openapi.gen.go