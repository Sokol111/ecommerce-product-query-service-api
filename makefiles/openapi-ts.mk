# ---- Variables (можна перевизначити в головному Makefile або через змінні середовища) ----
OPENAPI_FILE ?= openapi/openapi.yml
TS_API_DIR ?= gen/typescript
PROJECT_NAME ?= $(notdir $(CURDIR))
TS_PACKAGE_NAME ?= @sokol111/$(PROJECT_NAME)
# Версія береться з OpenAPI файлу (info.version)
TS_VERSION ?= $(shell grep -E '^\s+version:' $(OPENAPI_FILE) | head -1 | sed 's/.*version: *//' | tr -d ' ')

# =============================================================================
# OpenAPI TypeScript (orval)
# =============================================================================

.PHONY: openapi-ts-generate
openapi-ts-generate: _openapi-ts-clean _openapi-ts-gen _openapi-ts-package-json _openapi-ts-tsconfig _openapi-ts-build ## Generate TypeScript API client from OpenAPI spec
	@printf "$(COLOR_GREEN)✓ TypeScript API generation complete!$(COLOR_RESET)\n"
	@printf "$(COLOR_BLUE)  Package: $(TS_PACKAGE_NAME)@$(TS_VERSION)$(COLOR_RESET)\n"
	@printf "$(COLOR_BLUE)  Location: $(TS_API_DIR)/$(COLOR_RESET)\n"

.PHONY: openapi-ts-generate-fast
openapi-ts-generate-fast: _openapi-ts-clean _openapi-ts-gen _openapi-ts-package-json _openapi-ts-tsconfig _openapi-ts-index ## Generate TypeScript API (no build, for committing to git)
	@printf "$(COLOR_GREEN)✓ TypeScript API generation complete (source only)!$(COLOR_RESET)\n"
	@printf "$(COLOR_YELLOW)  Note: CI will build before publishing$(COLOR_RESET)\n"
	@printf "$(COLOR_BLUE)  Package: $(TS_PACKAGE_NAME)@$(TS_VERSION)$(COLOR_RESET)\n"
	@printf "$(COLOR_BLUE)  Location: $(TS_API_DIR)/$(COLOR_RESET)\n"

.PHONY: openapi-ts-clean
openapi-ts-clean: ## Remove generated TypeScript API files
	@printf "$(COLOR_BLUE)→ Cleaning generated TypeScript API files...$(COLOR_RESET)\n"
	@rm -rf $(TS_API_DIR)
	@printf "$(COLOR_GREEN)✓ Cleaned $(TS_API_DIR)/$(COLOR_RESET)\n"

.PHONY: openapi-ts-install-tools
openapi-ts-install-tools: ## Install OpenAPI TypeScript tools (orval)
	@printf "$(COLOR_BLUE)→ Installing orval...$(COLOR_RESET)\n"
	@npm install -g orval
	@printf "$(COLOR_GREEN)✓ orval installed$(COLOR_RESET)\n"

# ---- Internal targets ----

.PHONY: _openapi-ts-clean
_openapi-ts-clean:
	@printf "$(COLOR_BLUE)→ Cleaning JS client files...$(COLOR_RESET)\n"
	@rm -rf $(TS_API_DIR)
	@mkdir -p $(TS_API_DIR)

.PHONY: _openapi-ts-gen
_openapi-ts-gen:
	@printf "$(COLOR_BLUE)→ Generating TypeScript client (orval + axios)...$(COLOR_RESET)\n"
	@npx orval \
		--input $(OPENAPI_FILE) \
		--output $(TS_API_DIR)/api.ts \
		--client axios \
		--mode split

.PHONY: _openapi-ts-package-json
_openapi-ts-package-json:
	@printf "$(COLOR_BLUE)→ Generating package.json...$(COLOR_RESET)\n"
	@VERSION_NO_V=$$(echo "$(TS_VERSION)" | sed 's/^v//'); \
	printf '{\n  "name": "%s",\n  "description": "Generated TypeScript Axios client from OpenAPI for %s",\n  "version": "%s",\n  "main": "dist/index.js",\n  "types": "dist/index.d.ts",\n  "module": "dist/index.js",\n  "scripts": {\n    "build": "tsc",\n    "prepare": "npm run build"\n  },\n  "keywords": ["openapi", "typescript", "axios", "sdk"],\n  "license": "MIT",\n  "dependencies": {\n    "axios": "^1.10.0"\n  },\n  "devDependencies": {\n    "typescript": "^5"\n  },\n  "publishConfig": {\n    "access": "public"\n  },\n  "files": [\n    "dist"\n  ]\n}\n' \
		"$(TS_PACKAGE_NAME)" "$(PROJECT_NAME)" "$$VERSION_NO_V" > $(TS_API_DIR)/package.json

.PHONY: _openapi-ts-tsconfig
_openapi-ts-tsconfig:
	@printf "$(COLOR_BLUE)→ Generating tsconfig.json...$(COLOR_RESET)\n"
	@printf '{\n  "compilerOptions": {\n    "target": "ES2017",\n    "module": "ESNext",\n    "moduleResolution": "node",\n    "declaration": true,\n    "outDir": "dist",\n    "strict": true,\n    "esModuleInterop": true,\n    "skipLibCheck": true\n  },\n  "include": ["**/*.ts"]\n}\n' > $(TS_API_DIR)/tsconfig.json

.PHONY: _openapi-ts-index
_openapi-ts-index:
	@printf "$(COLOR_BLUE)→ Generating index.ts...$(COLOR_RESET)\n"
	@printf "export * from './api';\nexport * from './api.schemas';\n" > $(TS_API_DIR)/index.ts

.PHONY: _openapi-ts-build
_openapi-ts-build: _openapi-ts-index
	@printf "$(COLOR_BLUE)→ Installing dependencies and building...$(COLOR_RESET)\n"
	@cd $(TS_API_DIR) && npm install && npm run build
