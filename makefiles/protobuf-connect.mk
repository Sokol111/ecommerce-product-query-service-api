# ---- Configuration (auto-detected, can be overridden) ----
# Auto-detect the service name from proto/ subdirectory (e.g. proto/tenant/ -> tenant)
_PROTO_SUBDIR := $(shell ls proto 2>/dev/null | head -1)

RPC_PROTO_DIR   ?= proto/$(_PROTO_SUBDIR)/v1
EVENTS_PROTO_DIR ?= proto/$(_PROTO_SUBDIR)/events
PROTO_DIR       ?= proto
CONNECT_OUT     ?= gen/go/$(_PROTO_SUBDIR)/v1
CONNECT_PACKAGE ?= connect

# ---- Binaries ----
# BUF is defined in the root Makefile

# =============================================================================
# Connect (Buf + protoc-gen-connect-go)
# =============================================================================

.PHONY: connect-generate
connect-generate: _connect-check-tools _connect-clean-dir ## Generate Go Connect code from proto using buf
	@echo "$(COLOR_BLUE)→ Generating Connect code...$(COLOR_RESET)"
	$(BUF) generate --path $(RPC_PROTO_DIR) --template buf.gen.yaml
	@echo "$(COLOR_GREEN)✓ Connect generation complete!$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)  Generated files in $(CONNECT_OUT)/:$(COLOR_RESET)"
	@find $(CONNECT_OUT) -name '*.go' | head -20 | sed 's/^/    /'

.PHONY: connect-clean
connect-clean: ## Remove generated Connect files
	@echo "$(COLOR_BLUE)→ Cleaning generated Connect files...$(COLOR_RESET)"
	@rm -rf $(CONNECT_OUT)
	@mkdir -p $(CONNECT_OUT)
	@echo "$(COLOR_GREEN)✓ Cleaned $(CONNECT_OUT)/$(COLOR_RESET)"

.PHONY: connect-breaking
connect-breaking: _connect-check-tools ## Check for breaking proto changes against main
	@echo "$(COLOR_BLUE)→ Checking for breaking changes...$(COLOR_RESET)"
	$(BUF) breaking --against '.git#branch=main'
	@echo "$(COLOR_GREEN)✓ No breaking changes detected$(COLOR_RESET)"

.PHONY: connect-install-tools
connect-install-tools: ## Install buf and protoc plugins
	@echo "$(COLOR_BLUE)→ Installing buf...$(COLOR_RESET)"
	@go install github.com/bufbuild/buf/cmd/buf@v1.50.0
	@echo "$(COLOR_GREEN)✓ buf installed$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)→ Installing protoc-gen-go...$(COLOR_RESET)"
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.5
	@echo "$(COLOR_GREEN)✓ protoc-gen-go installed$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)→ Installing protoc-gen-connect-go...$(COLOR_RESET)"
	@go install connectrpc.com/connect/cmd/protoc-gen-connect-go@v1.18.1
	@echo "$(COLOR_GREEN)✓ protoc-gen-connect-go installed$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)→ Installing protoc-gen-go-grpc...$(COLOR_RESET)"
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1
	@echo "$(COLOR_GREEN)✓ protoc-gen-go-grpc installed$(COLOR_RESET)"

# ---- Internal targets ----

.PHONY: _connect-clean-dir
_connect-clean-dir:
	@echo "$(COLOR_BLUE)→ Cleaning $(CONNECT_OUT)...$(COLOR_RESET)"
	@rm -rf $(CONNECT_OUT)
	@mkdir -p $(CONNECT_OUT)

.PHONY: _connect-check-tools
_connect-check-tools:
	@command -v $(BUF) >/dev/null 2>&1 || \
		{ echo "$(COLOR_RED)✗ buf not found$(COLOR_RESET)"; \
		  echo "$(COLOR_YELLOW)  Install: make connect-install-tools$(COLOR_RESET)"; \
		  exit 1; }
	@echo "$(COLOR_GREEN)✓ buf found: $(BUF)$(COLOR_RESET)"

	@command -v protoc-gen-go >/dev/null 2>&1 || \
		{ echo "$(COLOR_RED)✗ protoc-gen-go not found$(COLOR_RESET)"; \
		  echo "$(COLOR_YELLOW)  Install: make connect-install-tools$(COLOR_RESET)"; \
		  exit 1; }
	@echo "$(COLOR_GREEN)✓ protoc-gen-go found$(COLOR_RESET)"

	@command -v protoc-gen-connect-go >/dev/null 2>&1 || \
		{ echo "$(COLOR_RED)✗ protoc-gen-connect-go not found$(COLOR_RESET)"; \
		  echo "$(COLOR_YELLOW)  Install: make connect-install-tools$(COLOR_RESET)"; \
		  exit 1; }
	@echo "$(COLOR_GREEN)✓ protoc-gen-connect-go found$(COLOR_RESET)"

	@command -v protoc-gen-go-grpc >/dev/null 2>&1 || \
		{ echo "$(COLOR_RED)✗ protoc-gen-go-grpc not found$(COLOR_RESET)"; \
		  echo "$(COLOR_YELLOW)  Install: make connect-install-tools$(COLOR_RESET)"; \
		  exit 1; }
	@echo "$(COLOR_GREEN)✓ protoc-gen-go-grpc found$(COLOR_RESET)"
