"""Unit tests for quantum detection modules."""

import pytest
import numpy as np
from quantum.autoencoder import HqcaDetector, HybridQuantumClassicalAutoencoder
from quantum.vqc import VariationalQuantumClassifier
from quantum.circuits import angle_encoding_circuit, variational_ansatz, quantum_kernel_estimation
from quantum.qrng import QuantumRandomNumberGenerator


class TestHybridQuantumClassicalAutoencoder:
    def test_forward_shape(self):
        model = HybridQuantumClassicalAutoencoder(input_dim=8, latent_dim=3)
        x = np.random.randn(10, 8).astype(np.float32)
        output = model.forward(x)
        assert output.shape == (10, 8)

    def test_reconstruction_error_shape(self):
        model = HybridQuantumClassicalAutoencoder()
        x = np.random.randn(5, 8).astype(np.float32)
        errors = model.reconstruction_error(x)
        assert errors.shape == (5,)

    def test_fit_reduces_loss(self):
        model = HybridQuantumClassicalAutoencoder(learning_rate=0.01)
        x = np.random.randn(100, 8).astype(np.float32)
        losses = model.fit(x, epochs=20)
        assert losses[-1] < losses[0]


class TestHqcaDetector:
    def test_detect_returns_correct_shape(self):
        detector = HqcaDetector(threshold=0.5)
        x = np.random.randn(50, 8).astype(np.float32)
        preds, errors = detector.detect(x)
        assert preds.shape == (50,)
        assert errors.shape == (50,)

    def test_set_threshold(self):
        detector = HqcaDetector(threshold=0.5)
        detector.set_threshold(0.8)
        assert detector.model.reconstruction_threshold == 0.8


class TestVariationalQuantumClassifier:
    def test_predict_shape(self):
        clf = VariationalQuantumClassifier(n_qubits=4, n_layers=2)
        x = np.random.randn(10, 4).astype(np.float32)
        preds = clf.predict(x)
        assert preds.shape == (10,)

    def test_predict_proba_range(self):
        clf = VariationalQuantumClassifier()
        x = np.random.randn(5, 4).astype(np.float32)
        probs = clf.predict_proba(x)
        assert np.all((probs >= 0) & (probs <= 1))

    def test_fit_improves_score(self):
        clf = VariationalQuantumClassifier(learning_rate=0.1)
        rng = np.random.default_rng(42)
        x = rng.standard_normal((200, 4)).astype(np.float32)
        y = (x.sum(axis=1) > 0).astype(np.float32)
        clf.fit(x[:150], y[:150], epochs=30)
        score = clf.score(x[150:], y[150:])
        assert score >= 0.4  # Better than random


class TestCircuits:
    def test_angle_encoding(self):
        features = np.random.randn(8)
        encoded = angle_encoding_circuit(features, n_qubits=4)
        assert encoded.shape == (4,)
        assert np.all(np.abs(encoded) <= 1.0)

    def test_variational_ansatz(self):
        params = np.random.randn(24)
        ansatz = variational_ansatz(params, n_qubits=4, n_layers=2)
        assert ansatz.shape == (2, 4, 3)

    def test_quantum_kernel(self):
        x1 = np.random.randn(5, 8)
        x2 = np.random.randn(3, 8)
        kernel = quantum_kernel_estimation(x1, x2)
        assert kernel.shape == (5, 3)
        assert np.all(kernel >= 0) and np.all(kernel <= 1)


class TestQRNG:
    def test_generate_bits_shape(self):
        qrng = QuantumRandomNumberGenerator()
        bits = qrng.generate_bits(128)
        assert bits.shape == (128,)

    def test_generate_bytes_length(self):
        qrng = QuantumRandomNumberGenerator()
        bytes_data = qrng.generate_bytes(32)
        assert len(bytes_data) == 32

    def test_random_hex_format(self):
        qrng = QuantumRandomNumberGenerator()
        hex_str = qrng.random_hex(16)
        assert len(hex_str) == 32
        assert all(c in "0123456789abcdef" for c in hex_str)

    def test_entropy_estimate_range(self):
        qrng = QuantumRandomNumberGenerator()
        entropy = qrng.entropy_estimate(1000)
        assert 0.8 <= entropy <= 1.0
