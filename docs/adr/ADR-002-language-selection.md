# ADR-002: Language Selection

## Status
Accepted

## Context
We need to choose programming languages for the GNSS spoofing detection system that balance performance, ecosystem support, and developer productivity.

## Decision
We will use a **hybrid Rust + Python** architecture:

| Layer | Language | Rationale |
|-------|----------|-----------|
| Signal parsing (NMEA, UBX, RTCM) | Rust | Performance-critical, memory-safe, WASM compilation |
| Classical detection algorithms | Rust | Real-time processing requirements |
| Quantum detection circuits | Python | Qiskit/CUDA-Q/PennyLane ecosystem |
| API Gateway | Go | Excellent concurrency for proxying |
| Frontend | TypeScript + Next.js | Rich UI ecosystem |
| CLI tools | Rust | Cross-platform distribution |
| MCP Server | Rust | Performance for tool serving |

## Consequences
- PyO3 bindings between Rust and Python
- `cxx` bridge for complex data sharing
- Build complexity from polyglot architecture
- Best-of-breed performance and ecosystem access
