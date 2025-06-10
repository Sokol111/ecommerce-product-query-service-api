OAPI_GEN := $(HOME)/go/bin/oapi-codegen
OPENAPI_FILE ?= openapi/openapi.yml
GEN_PKG := api
GEN_DIR ?= $(GEN_PKG)
JS_CLIENT_DIR ?= js-client
VERSION ?= 0.0.1

.PHONY: all client server types clean install-tools js

all: install-tools clean types server client

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

js:
	@echo "Generating JS client..."
	mkdir -p $(JS_CLIENT_DIR)
	openapi-generator-cli generate \
		-i $(OPENAPI_FILE) \
		-g typescript-axios \
		-o $(JS_CLIENT_DIR) \
		--additional-properties=useSingleRequestParameter=true

	@echo "Copying package.json and tsconfig.json..."
	cp template/package.json $(JS_CLIENT_DIR)/package.json
	cp template/tsconfig.json $(JS_CLIENT_DIR)/tsconfig.json

	@echo "Setting version..."
	cd $(JS_CLIENT_DIR) && npm version $(shell echo $(VERSION) | sed 's/^v//') --no-git-tag-version

	@echo "Installing dependencies..."
	cd $(JS_CLIENT_DIR) && npm install

	@echo "Building package..."
	cd $(JS_CLIENT_DIR) && npm run build

	@echo "JS client ready in $(JS_CLIENT_DIR)/dist"

clean:
	rm -rf $(GEN_DIR)