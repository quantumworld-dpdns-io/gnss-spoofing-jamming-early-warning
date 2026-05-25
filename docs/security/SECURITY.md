# GNSS Spoofing Detection Security Policies

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅ Active development |

## Security Posture

### Post-Quantum Cryptography
- Key encapsulation: ML-KEM-768 (FIPS 203)
- Digital signatures: ML-DSA-65 (FIPS 204)
- Stateless hashing: SLH-DSA (FIPS 205)

### Zero-Knowledge Proofs
- Noir circuits for signal provenance
- RISC Zero zkVM for verifiable computation

### Runtime Security
- Cilium Tetragon eBPF monitoring
- WASM plugin sandbox via Wasmtime
- Capability-based security model

### OWASP Top 10 Coverage
- Continuous automated testing via Robot Framework
- 70+ dedicated security test cases
- ZAP DAST scanning in CI pipeline

## Reporting Vulnerabilities

Contact: security@quantumworld.io
Response time: < 72 hours
PGP key: Available on request

## Security Audits

- Dependency scanning: cargo-audit (weekly)
- Container scanning: Trivy (per build)
- Code scanning: CodeQL + Semgrep (per PR)
- DAST scanning: OWASP ZAP (per release)
- Fuzzing: cargo-fuzz (continuous)
