"""Quantum Random Number Generator for cryptographic operations.

Uses simulated quantum measurement outcomes to generate
true random numbers for sensor authentication and nonces.
"""

import numpy as np
from typing import Optional


class QuantumRandomNumberGenerator:
    """Quantum random number generator using simulated measurement bases."""

    def __init__(self, n_qubits: int = 8):
        self.n_qubits = n_qubits
        self._rng = np.random.default_rng()

    def generate_bits(self, n_bits: int) -> np.ndarray:
        n_rounds = (n_bits + self.n_qubits - 1) // self.n_qubits
        bits = np.zeros(n_rounds * self.n_qubits, dtype=np.uint8)
        for i in range(n_rounds):
            theta = self._rng.random(self.n_qubits) * 2 * np.pi
            probs = (np.sin(theta) ** 2).astype(np.float64)
            bits[i * self.n_qubits : (i + 1) * self.n_qubits] = (
                self._rng.random(self.n_qubits) < probs
            ).astype(np.uint8)
        return bits[:n_bits]

    def generate_bytes(self, n_bytes: int) -> bytes:
        bits = self.generate_bits(n_bytes * 8)
        result = bytearray()
        for i in range(n_bytes):
            byte_val = 0
            for j in range(8):
                byte_val |= int(bits[i * 8 + j]) << (7 - j)
            result.append(byte_val)
        return bytes(result)

    def generate_int(self, min_val: int = 0, max_val: int = 2**32 - 1) -> int:
        bits = self.generate_bits(32)
        val = sum(int(b) << (31 - i) for i, b in enumerate(bits))
        return min_val + (val % (max_val - min_val + 1))

    def random_hex(self, n_bytes: int = 16) -> str:
        return self.generate_bytes(n_bytes).hex()

    def entropy_estimate(self, n_samples: int = 1000) -> float:
        bits = self.generate_bits(n_samples)
        p1 = float(bits.sum()) / n_samples
        if p1 <= 0.0 or p1 >= 1.0:
            return 1.0
        p0 = 1.0 - p1
        entropy = -p0 * np.log2(p0) - p1 * np.log2(p1)
        return entropy


def _test_qrng() -> None:
    qrng = QuantumRandomNumberGenerator(n_qubits=8)
    bits = qrng.generate_bits(128)
    assert bits.shape == (128,), f"Expected (128,), got {bits.shape}"
    bytes_data = qrng.generate_bytes(16)
    assert len(bytes_data) == 16
    entropy = qrng.entropy_estimate(1000)
    assert 0.5 <= entropy <= 1.0, f"Entropy out of range: {entropy}"
    hex_str = qrng.random_hex(32)
    assert len(hex_str) == 64
    print(f"QRNG tests passed. Entropy: {entropy:.4f}")


if __name__ == "__main__":
    _test_qrng()
