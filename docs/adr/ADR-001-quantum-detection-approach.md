# ADR-001: Quantum Detection Approach

## Status
Accepted

## Context
We need to choose a quantum computing approach for GNSS spoofing detection. The system must detect zero-day spoofing attacks with high accuracy while remaining practical for deployment.

## Decision
We will implement a **Hybrid Quantum-Classical Autoencoder (HQC-AE)** as the primary quantum detection method, based on the architecture from arXiv:2508.18085 which achieves ~97.71% detection accuracy.

Key decisions:
1. **Qiskit as primary quantum framework** — best library support, qiskit-machine-learning for VQC
2. **Angle encoding** for feature mapping from classical to quantum space
3. **Classical autoencoder + quantum variational layer** in latent space
4. **Reconstruction error threshold** for anomaly detection
5. **CUDA-Q as secondary backend** for GPU-accelerated simulation

## Consequences
- Python dependency on Qiskit ecosystem (~200MB)
- Requires quantum backend selection at startup
- Classical fallback detection when quantum unavailable
- Training requires classical preprocessing only
