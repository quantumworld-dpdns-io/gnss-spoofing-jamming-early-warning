"""Quantum circuit definitions for GNSS spoofing detection."""

from typing import Optional
import numpy as np


def angle_encoding_circuit(
    features: np.ndarray, n_qubits: Optional[int] = None
) -> np.ndarray:
    """Encode classical features into quantum state amplitudes.
    
    Uses angle encoding: each feature is mapped to a rotation angle.
    """
    n = n_qubits or len(features)
    encoded = np.zeros(min(len(features), n))
    for i in range(len(encoded)):
        encoded[i] = np.arctan(features[i]) * 2.0 / np.pi
    return encoded


def variational_ansatz(
    params: np.ndarray, n_qubits: int, n_layers: int
) -> np.ndarray:
    """Construct variational ansatz parameters for quantum circuit.
    
    Returns parameterized rotation angles for a hardware-efficient ansatz.
    """
    n_params = n_qubits * n_layers * 3
    if len(params) < n_params:
        params = np.pad(params, (0, n_params - len(params)))
    return params[:n_params].reshape(n_layers, n_qubits, 3)


def quantum_kernel_estimation(
    x1: np.ndarray, x2: np.ndarray, n_qubits: int = 4
) -> np.ndarray:
    """Estimate quantum kernel matrix using fidelity between encoded states.
    
    Uses overlap of angle-encoded states as a similarity measure.
    """
    n1, n2 = len(x1), len(x2)
    kernel = np.zeros((n1, n2), dtype=np.float32)
    for i in range(n1):
        v1 = angle_encoding_circuit(x1[i], n_qubits)
        for j in range(n2):
            v2 = angle_encoding_circuit(x2[j], n_qubits)
            overlap = np.abs(np.dot(v1, v2)) ** 2
            kernel[i, j] = overlap
    return kernel


def _test_circuits() -> None:
    rng = np.random.default_rng(42)
    features = rng.standard_normal(8)
    encoded = angle_encoding_circuit(features, n_qubits=4)
    assert encoded.shape == (4,), f"Expected (4,), got {encoded.shape}"
    params = rng.standard_normal(24)
    ansatz = variational_ansatz(params, n_qubits=4, n_layers=2)
    assert ansatz.shape == (2, 4, 3), f"Expected (2,4,3), got {ansatz.shape}"
    x1 = rng.standard_normal((5, 8))
    x2 = rng.standard_normal((3, 8))
    kernel = quantum_kernel_estimation(x1, x2)
    assert kernel.shape == (5, 3), f"Expected (5,3), got {kernel.shape}"
    print("Circuit tests passed.")


if __name__ == "__main__":
    _test_circuits()
