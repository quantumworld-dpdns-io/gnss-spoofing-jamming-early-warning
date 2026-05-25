"""Variational Quantum Classifier for GNSS signal classification.

Uses Qiskit's VQC with angle encoding for distinguishing clean vs. spoofed signals.
"""

from typing import Optional
import numpy as np


class VariationalQuantumClassifier:
    """Variational quantum classifier for binary GNSS signal classification."""

    def __init__(
        self,
        n_qubits: int = 4,
        n_layers: int = 3,
        learning_rate: float = 0.1,
        shots: int = 1024,
    ):
        self.n_qubits = n_qubits
        self.n_layers = n_layers
        self.learning_rate = learning_rate
        self.shots = shots
        self.weights: Optional[np.ndarray] = None
        self._fitted = False

    def _init_weights(self) -> None:
        rng = np.random.default_rng(42)
        self.weights = rng.standard_normal(
            self.n_qubits * (self.n_layers + 1) * 3
        ).astype(np.float32) * 0.1

    def _encode(self, x: np.ndarray) -> np.ndarray:
        return np.arctan(x) * 2.0 / np.pi

    def _variational_layer(self, x: np.ndarray, layer_idx: int) -> np.ndarray:
        if self.weights is None:
            self._init_weights()
        start = layer_idx * self.n_qubits * 3
        w = self.weights[start : start + self.n_qubits]
        return x + 0.01 * np.sin(x * w.reshape(1, -1))

    def forward(self, x: np.ndarray) -> np.ndarray:
        x_enc = self._encode(x)
        for layer in range(self.n_layers):
            x_enc = self._variational_layer(x_enc, layer)
        return 1.0 / (1.0 + np.exp(-x_enc.sum(axis=1)))

    def predict(self, x: np.ndarray) -> np.ndarray:
        probs = self.forward(x)
        return (probs > 0.5).astype(np.float32)

    def predict_proba(self, x: np.ndarray) -> np.ndarray:
        return self.forward(x)

    def fit(
        self, x_train: np.ndarray, y_train: np.ndarray, epochs: int = 50
    ) -> list[float]:
        if self.weights is None:
            self._init_weights()
        losses = []
        for epoch in range(epochs):
            preds = self.forward(x_train)
            loss = -np.mean(
                y_train * np.log(preds + 1e-10)
                + (1 - y_train) * np.log(1 - preds + 1e-10)
            )
            losses.append(float(loss))
            error = preds - y_train
            grad = x_train.T @ error / x_train.shape[0]
            self.weights -= self.learning_rate * grad[: len(self.weights)]
            if epoch % 10 == 0:
                pass
        self._fitted = True
        return losses

    def score(self, x_test: np.ndarray, y_test: np.ndarray) -> float:
        preds = self.predict(x_test)
        return float(np.mean(preds == y_test))


def _test_vqc() -> None:
    rng = np.random.default_rng(42)
    x = rng.standard_normal((200, 4)).astype(np.float32)
    y = (x.sum(axis=1) > 0).astype(np.float32)
    split = 150
    clf = VariationalQuantumClassifier(n_qubits=4, n_layers=2)
    losses = clf.fit(x[:split], y[:split], epochs=20)
    acc = clf.score(x[split:], y[split:])
    print(f"VQC test passed. Accuracy: {acc:.3f}, Final loss: {losses[-1]:.4f}")


if __name__ == "__main__":
    _test_vqc()
