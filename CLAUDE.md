# GNSS Spoofing/Jamming Early Warning System

## Project Overview
SaaS platform for detecting GNSS spoofing and jamming through crowdsourced signal analysis, combining classical ML with quantum-enhanced detection (HQC-AE).

## Tech Stack
- **Rust**: Detection engine, MCP server, signal parsing
- **Python**: Quantum detection (Qiskit), ML models
- **Go**: API Gateway
- **TypeScript/Next.js**: Frontend dashboard
- **Robot Framework**: System/security testing
- **DuckDB/LanceDB/Redis**: Data storage
- **Qiskit**: Primary quantum computing framework
- **CUDA-Q**: GPU-accelerated quantum simulation

## Key Commands
```bash
make build          # Build all components
make test           # Run all tests
make test-robot     # Run Robot Framework tests (incl. OWASP)
make quantum        # Run quantum validation
make lint           # Lint all code
make security-audit # Security scanning
make release        # Create release
make docker-build   # Build Docker images
make fuzz           # Run fuzz tests
```

## Architecture
```
src/detection-engine/   # Rust crates + Python packages
  crates/               # Rust crates (gnss-parser, signal-processing, quantum-detector, alert-engine)
  python/              # Python packages (quantum, gnss_core)
src/mcp-server/        # MCP server (Rust)
src/api-gateway/       # Go API gateway
src/frontend/          # Next.js frontend
src/cli/              # CLI tools
src/agent-skills/      # AI agent skill definitions
tests/                # Test suites
  robot/              # Robot Framework (acceptance, security, performance)
  unit/               # Unit tests
  integration/        # Integration tests
  fuzz/               # Fuzz test harnesses
```

## Quantum Components
- `python/quantum/autoencoder.py` - HQC-AE (97.71% accuracy)
- `python/quantum/vqc.py` - Variational Quantum Classifier
- `python/quantum/circuits.py` - Quantum circuit definitions
- `python/quantum/qrng.py` - Quantum random number generator

## Security
- OWASP Top 10 automated via Robot Framework (70+ tests)
- Post-quantum cryptography (ML-KEM, ML-DSA, SLH-DSA via liboqs)
- Zero-knowledge proofs (Noir, RISC Zero)
- WASM sandbox for plugins (Wasmtime)
- Cilium Tetragon for runtime security
