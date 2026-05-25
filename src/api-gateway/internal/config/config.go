package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port            string
	LogLevel        string
	RedisURL        string
	DatabaseURL     string
	MCPEndpoint     string
	RateLimit       int
	RateLimitWindow time.Duration
	JWTSecret       string
	AllowedOrigins  []string
	Environment     string
}

func Load() *Config {
	return &Config{
		Port:            getEnv("PORT", "8080"),
		LogLevel:        getEnv("LOG_LEVEL", "info"),
		RedisURL:        getEnv("REDIS_URL", "redis://localhost:6379"),
		DatabaseURL:     getEnv("DATABASE_URL", "duckdb:///data/gnss.duckdb"),
		MCPEndpoint:     getEnv("MCP_ENDPOINT", "127.0.0.1:8090"),
		RateLimit:       getEnvInt("RATE_LIMIT", 100),
		RateLimitWindow: time.Duration(getEnvInt("RATE_LIMIT_WINDOW_SECS", 60)) * time.Second,
		JWTSecret:       getEnv("JWT_SECRET", "change-me-in-production"),
		AllowedOrigins:  []string{"*"},
		Environment:     getEnv("ENVIRONMENT", "development"),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if val := os.Getenv(key); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return fallback
}
