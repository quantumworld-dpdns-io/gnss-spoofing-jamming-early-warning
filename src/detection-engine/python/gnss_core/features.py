"""Signal feature extraction for GNSS spoofing detection."""

import numpy as np
from typing import Optional
from .models import SignalObservation


class SignalFeatures:
    def __init__(self, observations: list[SignalObservation]):
        self.observations = observations
        self.snr_values = np.array([o.snr_db_hz for o in observations], dtype=np.float32)
        self.doppler_values = np.array([o.doppler_shift for o in observations], dtype=np.float32)
        self.pseudorange_values = np.array([o.pseudorange for o in observations], dtype=np.float64)
        self.carrier_phase_values = np.array([o.carrier_phase for o in observations], dtype=np.float64)

    @property
    def snr_mean(self) -> float:
        return float(self.snr_values.mean()) if len(self.snr_values) > 0 else 0.0

    @property
    def snr_std(self) -> float:
        return float(self.snr_values.std()) if len(self.snr_values) > 1 else 0.0

    @property
    def snr_min(self) -> float:
        return float(self.snr_values.min()) if len(self.snr_values) > 0 else 0.0

    @property
    def snr_max(self) -> float:
        return float(self.snr_values.max()) if len(self.snr_values) > 0 else 0.0

    @property
    def doppler_spread(self) -> float:
        return float(self.doppler_values.max() - self.doppler_values.min()) \
            if len(self.doppler_values) > 0 else 0.0

    @property
    def pseudorange_spread(self) -> float:
        return float(self.pseudorange_values.max() - self.pseudorange_values.min()) \
            if len(self.pseudorange_values) > 0 else 0.0

    def to_vector(self) -> np.ndarray:
        return np.array([
            self.snr_mean,
            self.snr_std,
            self.snr_min,
            self.snr_max,
            self.doppler_spread,
            self.pseudorange_spread,
            float(self.pseudorange_values.mean()) if len(self.pseudorange_values) > 0 else 0.0,
            float(self.carrier_phase_values.mean()) if len(self.carrier_phase_values) > 0 else 0.0,
        ], dtype=np.float32)


class FeatureExtractor:
    def __init__(self, window_size: int = 20):
        self.window_size = window_size

    def extract(self, observations: list[SignalObservation]) -> np.ndarray:
        features = SignalFeatures(observations)
        return features.to_vector()

    def extract_batch(self, observations_batch: list[list[SignalObservation]]) -> np.ndarray:
        return np.array([self.extract(batch) for batch in observations_batch])
