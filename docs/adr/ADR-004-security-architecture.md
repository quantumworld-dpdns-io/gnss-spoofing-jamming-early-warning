# ADR-004: Security Architecture

## Status
Accepted

## Context
GNSS spoofing data is sensitive infrastructure data. The system must resist current and future attacks, including quantum-capable adversaries.

## Decision
We implement a **defense-in-depth security architecture**:

1. **Post-Quantum Cryptography (liboqs)**:
   - ML-KEM-768 for key encapsulation (FIPS 203)
   - ML-DSA-65 for digital signatures (FIPS 204)
   - SLH-DSA for stateless hashing (FIPS 205)
   - Hybrid classical/PQC TLS handshake

2. **Zero-Knowledge Proofs (Noir + RISC Zero)**:
   - Signal provenance verification without revealing sensor location
   - Verifiable computation of detection results
   - Privacy-preserving sensor data sharing

3. **WASI/Wasmtime Plugin Sandbox**:
   - Third-party detector modules in isolated WASM
   - Capability-based security model
   - Resource-limited execution

4. **OWASP Top 10 Compliance**:
   - Automated testing via Robot Framework (70+ test cases)
   - ZAP integration for DAST scanning
   - Regular dependency auditing

## Consequences
- PQC adds ~2x key sizes vs. classical crypto
- ZKP adds computational overhead (~1-5s per proof)
- WASM sandbox limits third-party plugin capabilities
- Full OWASP compliance requires ongoing maintenance
