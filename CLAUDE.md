# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is the **API contract repo** for `ecommerce-product-query-service` (the CQRS read side
for products). It is *not* a service — it holds the protobuf source of truth and the generated
client SDKs that consumers import. It is one of the `ecommerce-*-api` repos in the larger
multi-repo workspace (see the workspace root `CLAUDE.md` for the release-then-bump model, the
`go.work` local-resolution rule, and how consumers depend on this module).

The Go module published from here is `github.com/Sokol111/ecommerce-product-query-service-api`;
the TypeScript package is `@sokol111/ecommerce-product-query-service-api` (published to GitHub
Packages). Both are built from a single `.proto`.

## The one rule that matters

**Edit `proto/` and regenerate. Never hand-edit anything under `gen/`.** Both `gen/go` and
`gen/typescript` are fully derived from `proto/product_query/v1/product_query.proto`. Every
generated file is wiped and rewritten by `make generate`. The workspace-level PreToolUse hook
also **blocks** direct edits to `gen/go` and `gen/typescript`.

Note: the generated *TypeScript sources* (`*_pb.ts`, `index.ts`, `package.json`, `tsconfig.json`)
ARE committed to git; only `node_modules/`, `dist/`, and `package-lock.json` are gitignored (CI
builds those before publishing). The generated *Go sources* are committed as the module surface.

## Commands

```bash
make generate            # lint + generate TS client + generate Go client (the main command)
make lint                # buf lint only
make format              # buf format -w (rewrites .proto in place)
make connect-breaking    # check proto for breaking changes (see caveat below)
make tidy                # go mod tidy
make update-proto-deps   # refresh buf.lock (protovalidate dep)
make help                # list all targets, grouped
```

First-time setup on a fresh machine installs the protoc plugins:
```bash
make connect-install-tools   # buf + protoc-gen-{go,connect-go,go-grpc}
```
TypeScript generation needs no local tools — it uses buf remote plugins (`protoc-gen-es`).

**Caveat:** `make connect-breaking` diffs against `.git#branch=main`, but the actual default
branch here is `master`. The target as written will fail or check the wrong ref locally — the
authoritative breaking-change gate runs in the release workflow, not this local target.

## Generation pipeline (what `make generate` actually does)

`make generate` = `lint` → `connect-ts-generate` → `connect-generate`. The logic lives in two
included makefiles under `makefiles/` (`protobuf-connect.mk` for Go, `connect-ts.mk` for TS),
not in the root `Makefile`. Key behaviors to know:

- The proto subdir under `proto/` is **auto-detected** (`ls proto | head -1` → `product_query`),
  so paths like `RPC_PROTO_DIR=proto/product_query/v1` are derived, not hardcoded.
- Go output is driven by `buf.gen.yaml` (three plugins: `protoc-gen-go`, `protoc-gen-connect-go`,
  `protoc-gen-go-grpc`) → `gen/go/product_query/v1/`, including a `productqueryv1connect/`
  package for the Connect handler/client.
- TS output is driven by `buf.gen.ts.yaml` (`protoc-gen-es`, `target=ts`) → `gen/typescript/`.
  The `connect-ts.mk` target then synthesizes `package.json` + `tsconfig.json` from templates
  (version pulled from the `VERSION` file), generates a barrel `index.ts`, and does an
  `npm install && tsc` build (removing `node_modules` afterward).

## Contract shape

Single service, `ProductQueryService` (RPC-only; unlike some other services in the workspace,
this API defines **no Kafka event schemas** — there is no `proto/product_query/events/`). Four
read RPCs:
- `GetProductById`, `GetRandomProducts`, `GetProductList` (paged, with category/price/attribute
  filters + sort), `GetProductFacets` (attribute facets + price range for a category).

The `Product` / `AttributeValue` / `AttributeFacet` messages are the read-model projection this
query service exposes — richer than the write-side catalog contract (e.g. resolved image URLs,
faceting types). When changing these, remember the read model is populated from catalog Kafka
events in the consuming service; a field added here must actually be projectable there.

## Consumer wiring helper

`pkg/client/grpc.go` is a hand-written (non-generated) `fx.Module()` that wires a native gRPC
client for `ProductQueryService`, reading config from koanf under key `product-query.grpc`. This
is the intended way for other services to consume this API — provide `client.Module()` in their
`main.go` rather than dialing manually. It layers on `ecommerce-commons/pkg/grpc/client`.

## Releasing

Bumping the `VERSION` file and pushing to `master` triggers `.github/workflows/release.yml`,
which delegates to the reusable `api-release.yml` in `ecommerce-infrastructure`. That workflow
runs the breaking-change check (skippable via `workflow_dispatch` input `skip_breaking`), tags
the Go module, and publishes the TS package. Do not tag or publish by hand.
