"""Quantum-enhanced GNSS spoofing detection package.

Integrates Qiskit, CUDA-Q, and PennyLane for quantum-classical hybrid detection.
"""

from .autoencoder import HqcaDetector, HybridQuantumClassicalAutoencoder
from .vqc import VariationalQuantumClassifier
from .qrng import QuantumRandomNumberGenerator
from .circuits import (
    angle_encoding_circuit,
    variational_ansatz,
    quantum_kernel_estimation,
)

__all__ = [
    "HqcaDetector",
    "HybridQuantumClassicalAutoencoder",
    "VariationalQuantumClassifier",
    "QuantumRandomNumberGenerator",
    "angle_encoding_circuit",
    "variational_ansatz",
    "quantum_kernel_estimation",
]
