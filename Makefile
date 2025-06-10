include .env

OAPI_GEN := $(HOME)/go/bin/oapi-codegen
OPENAPI_FILE ?= openapi/openapi.yml
GEN_PKG := api
GEN_DIR ?= $(GEN_PKG)
JS_CLIENT_DIR ?= js-client
VERSION ?= 0.0.1
VERSION_NO_V := $(VERSION:v%=%)
TEMPLATE_DIR ?= template

.PHONY: install-tools types server client js-generate js-package js-tsconfig js-build js clean

install-tools:
	@echo "Installing tools if missing..."
	@which oapi-codegen >/dev/null || go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest
	@which openapi-generator-cli >/dev/null || npm install -g @openapitools/openapi-generator-cli
	@which envsubst >/dev/null || sudo apt-get update && sudo apt-get install -y gettext

types:
	echo "Generating types (models)..."
	mkdir -p $(GEN_DIR)
	$(OAPI_GEN) -generate types -package $(GEN_PKG) -o $(GEN_DIR)/models.gen.go $(OPENAPI_FILE)

server:
	echo "Generating Go server..."
	mkdir -p $(GEN_DIR)
	$(OAPI_GEN) -generate gin-server,strict-server -package $(GEN_PKG) -o $(GEN_DIR)/server.gen.go $(OPENAPI_FILE)

client:
	echo "Generating Go client..."
	mkdir -p $(GEN_DIR)
	$(OAPI_GEN) -generate client -package $(GEN_PKG) -o $(GEN_DIR)/client.gen.go $(OPENAPI_FILE)

js-generate:
	echo "Generating JS client..."
	mkdir -p $(JS_CLIENT_DIR)
	openapi-generator-cli generate \
		-i $(OPENAPI_FILE) \
		-g typescript-axios \
		-o $(JS_CLIENT_DIR) \
		--additional-properties=useSingleRequestParameter=true

js-package:
	echo "Generating package.json..."
	PACKAGE_NAME=$(PACKAGE_NAME) \
	VERSION=$(VERSION_NO_V) \
	PROJECT_NAME=$(PROJECT_NAME) \
	AUTHOR=$(AUTHOR) \
	REPOSITORY_URL=$(REPOSITORY_URL) \
	envsubst < $(TEMPLATE_DIR)/package.json.template > $(JS_CLIENT_DIR)/package.json

js-tsconfig:
	echo "Generating tsconfig.json..."
	cp $(TEMPLATE_DIR)/tsconfig.json.template $(JS_CLIENT_DIR)/tsconfig.json

js-build:
	echo "Installing dependencies..."
	cd $(JS_CLIENT_DIR) && npm install
	echo "Building package..."
	cd $(JS_CLIENT_DIR) && npm run build
	echo "JS client ready in $(JS_CLIENT_DIR)/dist"
	echo "Generated package.json:"
	cat $(JS_CLIENT_DIR)/package.json

js: js-generate js-package js-tsconfig js-build

clean:
	echo "Cleaning generated files..."
	rm -rf $(GEN_DIR)