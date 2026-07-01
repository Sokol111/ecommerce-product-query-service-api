package client

import (
	"github.com/knadh/koanf/v2"
	"go.uber.org/fx"

	grpcclient "github.com/Sokol111/ecommerce-commons/pkg/grpc/client"
	productv1 "github.com/Sokol111/ecommerce-product-query-service-api/gen/connect/product_query/v1"
)

// Module wires a native gRPC client for ProductQueryService.
// Configuration is read from koanf under key "product-query.grpc".
func Module() fx.Option {
	return fx.Module("product-query-grpc-client",
		fx.Provide(func(k *koanf.Koanf) (grpcclient.Config, error) {
			return grpcclient.LoadConfig(k, "product-query.grpc")
		}, fx.Private),
		fx.Provide(grpcclient.NewConn, fx.Private),
		fx.Provide(productv1.NewProductQueryServiceClient),
	)
}
