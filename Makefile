OAPI_GEN := $(HOME)/go/bin/oapi-codegen
OPENAPI_FILE ?= openapi/openapi.yml
GEN_PKG := api
GEN_DIR ?= $(GEN_PKG)
JS_CLIENT_DIR ?= js-client
VERSION ?= 0.0.1
TEMPLATE_DIR ?= template

.PHONY: install-tools types server client js-generate js-config js-version js-build js clean

install-tools:
	@which oapi-codegen >/dev/null || go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest
	@which openapi-generator-cli >/dev/null || npm install -g @openapitools/openapi-generator-cli

types:
	@echo "Generating types (models)..."
	mkdir -p $(GEN_DIR)
	$(OAPI_GEN) -generate types -package $(GEN_PKG) -o $(GEN_DIR)/models.gen.go $(OPENAPI_FILE)

server:
	@echo "Generating Go server..."
	mkdir -p $(GEN_DIR)
	$(OAPI_GEN) -generate gin-server,strict-server -package $(GEN_PKG) -o $(GEN_DIR)/server.gen.go $(OPENAPI_FILE)

client:
	@echo "Generating Go client..."
	mkdir -p $(GEN_DIR)
	$(OAPI_GEN) -generate client -package $(GEN_PKG) -o $(GEN_DIR)/client.gen.go $(OPENAPI_FILE)

js-generate:
	@echo "Generating JS client..."
	mkdir -p $(JS_CLIENT_DIR)
	openapi-generator-cli generate \
		-i $(OPENAPI_FILE) \
		-g typescript-axios \
		-o $(JS_CLIENT_DIR) \
		--additional-properties=useSingleRequestParameter=true

js-config:
	@echo "Copying package.json and tsconfig.json..."
	cp $(TEMPLATE_DIR)/package.json $(JS_CLIENT_DIR)/package.json
	cp $(TEMPLATE_DIR)/tsconfig.json $(JS_CLIENT_DIR)/tsconfig.json

js-version:
	@echo "Setting version..."
	cd $(JS_CLIENT_DIR) && npm version $(shell echo $(VERSION) | sed 's/^v//') --no-git-tag-version

js-build:
	@echo "Installing dependencies..."
	cd $(JS_CLIENT_DIR) && npm install
	@echo "Building package..."
	cd $(JS_CLIENT_DIR) && npm run build
	@echo "JS client ready in $(JS_CLIENT_DIR)/dist"

js: js-generate js-config js-version js-build

clean:
	rm -rf $(GEN_DIR)