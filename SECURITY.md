# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**Email**: security@quantumworld.io  
**PGP Key**: Available at https://quantumworld.io/security/pgp  
**Response Time**: We aim to respond within 72 hours.  
**Disclosure Policy**: Coordinated disclosure — 90 days after fix release.

## Security Measures

### Post-Quantum Cryptography
- ML-KEM-768 (FIPS 203) for key exchange
- ML-DSA-65 (FIPS 204) for digital signatures
- SLH-DSA (FIPS 205) for stateless hashing

### Zero-Knowledge Proofs
- Noir circuits for signal provenance verification
- RISC Zero zkVM for verifiable computation

### Runtime Protection
- Cilium Tetragon eBPF-based runtime security
- WASM sandbox for third-party detection plugins
- Seccomp/AppArmor profiles for containers

### Supply Chain Security
- SLSA Level 3 provenance attestation
- Signed releases with Sigstore/cosign
- SBOM generation with Syft

### Automated Security Testing
- OWASP Top 10 via Robot Framework (70+ tests)
- OWASP ZAP DAST scanning
- Continuous fuzzing (cargo-fuzz, atheris)
- Dependency auditing (cargo-audit, safety, npm audit)
- Container scanning (Trivy, Dockle)
- Code scanning (CodeQL, Semgrep)
