# ADR-010: Testing Strategy

## Status
Accepted

## Context
A GNSS spoofing detection system requires rigorous testing across multiple dimensions: functional correctness, security resilience, performance under load, and quantum algorithm accuracy.

## Decision
We implement a **multi-layered testing strategy**:

### Layer 1: Unit Tests
- Rust: `#[cfg(test)]` modules in every crate
- Python: pytest with hypothesis property-based testing
- Go: native `_test.go` files
- Coverage target: ≥90%

### Layer 2: Integration Tests
- Cross-component signal pipeline tests
- Database integration tests (DuckDB, LanceDB, Redis)
- Quantum circuit validation against known datasets (TEXBAT, FGI-SpoofRepo)

### Layer 3: Robot Framework (System Tests)
- **Acceptance tests**: 20+ test cases covering all API endpoints and MCP tools
- **Security tests**: 70+ OWASP Top 10 test cases including:
  - A1: Broken Access Control (5 tests)
  - A2: Cryptographic Failures (3 tests)
  - A3: Injection (9 tests: SQLi, NoSQLi, command injection)
  - A4: Insecure Design (3 tests)
  - A5: Security Misconfiguration (3 tests)
  - A6: Vulnerable Components (1 test)
  - A7: Authentication Failures (3 tests)
  - A8: Data Integrity (2 tests)
  - A9: Logging Failures (1 test)
  - A10: SSRF (3 tests)
- **Performance tests**: Throughput, latency, concurrent requests
- **GNSS-specific security tests**: Signal replay, data poisoning, injection

### Layer 4: Fuzz Testing
- Rust: `cargo-fuzz` for NMEA/UBX/RTCM parsers
- Python: `atheris` for signal processing
- 24/7 fuzzing infrastructure in CI

### Layer 5: Chaos Engineering
- Network partition tests
- Sensor disconnection scenarios
- Quantum backend failure recovery

### Layer 6: OWASP ZAP Integration
- Automated DAST scanning in CI pipeline
- Full scan on release candidates
- Baseline scan on every PR

## Consequences
- ~1,000+ total test cases across all layers
- CI pipeline time: ~15-30 minutes
- Robot Framework + ZAP adds ~5 minutes to CI
- Fuzzing runs as separate 24/7 workflow
