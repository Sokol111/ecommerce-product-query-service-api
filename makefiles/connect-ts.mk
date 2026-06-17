# ---- Variables (можна перевизначити в головному Makefile або через змінні середовища) ----
TS_API_DIR ?= gen/typescript
PROJECT_NAME ?= $(notdir $(CURDIR))
TS_PACKAGE_NAME ?= @sokol111/$(PROJECT_NAME)
# Версія береться з файлу VERSION
TS_VERSION ?= $(shell cat VERSION 2>/dev/null | tr -d '[:space:]' || echo "0.1.0")

BUF ?= $(shell which buf 2>/dev/null || echo "$$(go env GOPATH)/bin/buf")

# =============================================================================
# Connect TypeScript (buf + protoc-gen-es + protoc-gen-connect-es)
# =============================================================================

.PHONY: connect-ts-generate
connect-ts-generate: _connect-ts-clean _connect-ts-gen _connect-ts-package-json _connect-ts-tsconfig _connect-ts-build ## Generate TypeScript Connect client from proto
	@printf "$(COLOR_GREEN)✓ TypeScript Connect generation complete!$(COLOR_RESET)\n"
	printf "$(COLOR_BLUE)  Package: $(TS_PACKAGE_NAME)@$(TS_VERSION)$(COLOR_RESET)\n"
	printf "$(COLOR_BLUE)  Location: $(TS_API_DIR)/$(COLOR_RESET)\n"

.PHONY: connect-ts-generate-fast
connect-ts-generate-fast: _connect-ts-clean _connect-ts-gen _connect-ts-package-json _connect-ts-tsconfig _connect-ts-index ## Generate TypeScript Connect client (no build, for committing to git)
	@printf "$(COLOR_GREEN)✓ TypeScript Connect generation complete (source only)!$(COLOR_RESET)\n"
	printf "$(COLOR_YELLOW)  Note: CI will build before publishing$(COLOR_RESET)\n"
	printf "$(COLOR_BLUE)  Package: $(TS_PACKAGE_NAME)@$(TS_VERSION)$(COLOR_RESET)\n"
	printf "$(COLOR_BLUE)  Location: $(TS_API_DIR)/$(COLOR_RESET)\n"

.PHONY: connect-ts-clean
connect-ts-clean: ## Remove generated TypeScript Connect files
	@printf "$(COLOR_BLUE)→ Cleaning generated TypeScript files...$(COLOR_RESET)\n"
	rm -rf $(TS_API_DIR)
	printf "$(COLOR_GREEN)✓ Cleaned $(TS_API_DIR)/$(COLOR_RESET)\n"

.PHONY: connect-ts-install-tools
connect-ts-install-tools: ## Install tools for TypeScript Connect generation (buf uses remote plugins — no local install needed)
	@printf "$(COLOR_BLUE)→ TypeScript generation uses buf remote plugins — no additional tools required$(COLOR_RESET)\n"
	printf "$(COLOR_GREEN)✓ Done$(COLOR_RESET)\n"

# ---- Internal targets ----

.PHONY: _connect-ts-clean
_connect-ts-clean:
	@rm -rf $(TS_API_DIR)
	mkdir -p $(TS_API_DIR)

.PHONY: _connect-ts-gen
_connect-ts-gen:
	@printf "$(COLOR_BLUE)→ Generating TypeScript Connect client (buf + protoc-gen-es)...$(COLOR_RESET)\n"
	$(BUF) generate --template buf.gen.ts.yaml

.PHONY: _connect-ts-package-json
_connect-ts-package-json:
	@printf "$(COLOR_BLUE)→ Generating package.json...$(COLOR_RESET)\n"; \
	VERSION_NO_V=$$(echo "$(TS_VERSION)" | sed 's/^v//'); \
	printf '{\n  "name": "%s",\n  "description": "Generated TypeScript Connect client from proto for %s",\n  "version": "%s",\n  "type": "module",\n  "main": "dist/index.js",\n  "types": "dist/index.d.ts",\n  "module": "dist/index.js",\n  "scripts": {\n    "build": "tsc",\n    "prepare": "npm run build"\n  },\n  "keywords": ["protobuf", "connect", "typescript", "grpc", "sdk"],\n  "license": "MIT",\n  "peerDependencies": {\n    "@bufbuild/protobuf": ">=2.0.0",\n    "@connectrpc/connect": ">=2.0.0"\n  },\n  "devDependencies": {\n    "@bufbuild/protobuf": "^2",\n    "@connectrpc/connect": "^2",\n    "typescript": "^5"\n  },\n  "publishConfig": {\n    "access": "public",\n    "registry": "https://npm.pkg.github.com"\n  },\n  "files": [\n    "dist"\n  ]\n}\n' \
		"$(TS_PACKAGE_NAME)" "$(PROJECT_NAME)" "$$VERSION_NO_V" > $(TS_API_DIR)/package.json

.PHONY: _connect-ts-tsconfig
_connect-ts-tsconfig:
	@printf "$(COLOR_BLUE)→ Generating tsconfig.json...$(COLOR_RESET)\n"; \
	printf '{\n  "compilerOptions": {\n    "target": "ES2017",\n    "module": "ESNext",\n    "moduleResolution": "bundler",\n    "declaration": true,\n    "outDir": "dist",\n    "strict": true,\n    "esModuleInterop": true,\n    "skipLibCheck": true\n  },\n  "include": ["**/*.ts"]\n}\n' > $(TS_API_DIR)/tsconfig.json

.PHONY: _connect-ts-index
_connect-ts-index:
	@printf "$(COLOR_BLUE)→ Generating index.ts...$(COLOR_RESET)\n"; \
	for f in $$(find $(TS_API_DIR) -name '*_pb.ts' | sort); do \
		rel="$${f#$(TS_API_DIR)/}"; \
		echo "export * from './$${rel%.ts}.js';"; \
	done > $(TS_API_DIR)/index.ts

.PHONY: _connect-ts-build
_connect-ts-build: _connect-ts-index
	@printf "$(COLOR_BLUE)→ Installing dependencies and building...$(COLOR_RESET)\n"
	cd $(TS_API_DIR) && npm install && npm run build
