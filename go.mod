module github.com/quantumworld-dpdns-io/gnss-spoofing-jamming-early-warning/api-gateway

go 1.23

require (
	github.com/gorilla/mux v1.8.1
	github.com/gorilla/websocket v1.5.3
	github.com/redis/go-redis/v9 v9.7.0
	github.com/rs/cors v1.11.1
	github.com/sirupsen/logrus v1.9.3
	go.opentelemetry.io/otel v1.33.0
	go.opentelemetry.io/otel/exporters/otlp/otlptrace v1.33.0
	go.opentelemetry.io/otel/sdk v1.33.0
	google.golang.org/grpc v1.69.0
	google.golang.org/protobuf v1.36.0
)
