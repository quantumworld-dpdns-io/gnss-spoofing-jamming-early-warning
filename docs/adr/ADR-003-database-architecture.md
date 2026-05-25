# ADR-003: Database Architecture

## Status
Accepted

## Context
GNSS spoofing detection requires multiple storage patterns: time-series signal data, vector embeddings for fingerprint matching, analytical queries, and real-state caching.

## Decision
We adopt a **polyglot database architecture**:

| Database | Purpose | Rationale |
|----------|---------|-----------|
| DuckDB | Embedded analytics on signal features | Zero-ops, SQL interface, Parquet support |
| LanceDB | Vector storage for signal fingerprints | Multimodal, columnar, fast ANN search |
| Redis | Real-time caching, pub/sub, rate limiting | Sub-millisecond, pub/sub for heatmap updates |
| Apache Iceberg | Historical signal data lakehouse | Time-travel, ACID, schema evolution |
| Trino | Federated queries across all stores | Unified SQL access |

## Consequences
- Increased operational complexity
- DuckDB ideal for embedded/edge deployment
- Iceberg/Trino for centralized cloud analytics
- Redis for hot-path caching reduces DB load
