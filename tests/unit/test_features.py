"""Unit tests for signal feature extraction."""

import pytest
import numpy as np
from datetime import datetime
from gnss_core.features import SignalFeatures, FeatureExtractor
from gnss_core.models import SignalObservation, GnssSource


class TestSignalFeatures:
    @pytest.fixture
    def observations(self):
        return [
            SignalObservation(GnssSource.GPS, 1, 45.0, 0.0, 0.0, 0.5, datetime.utcnow()),
            SignalObservation(GnssSource.GPS, 2, 44.0, 0.0, 0.0, 0.3, datetime.utcnow()),
            SignalObservation(GnssSource.GALILEO, 3, 46.0, 0.0, 0.0, 0.4, datetime.utcnow()),
            SignalObservation(GnssSource.GLONASS, 4, 43.0, 0.0, 0.0, 1.2, datetime.utcnow()),
        ]

    def test_snr_mean(self, observations):
        features = SignalFeatures(observations)
        assert abs(features.snr_mean - 44.5) < 0.01

    def test_snr_std(self, observations):
        features = SignalFeatures(observations)
        assert features.snr_std > 0

    def test_snr_min(self, observations):
        features = SignalFeatures(observations)
        assert features.snr_min == 43.0

    def test_snr_max(self, observations):
        features = SignalFeatures(observations)
        assert features.snr_max == 46.0

    def test_doppler_spread(self, observations):
        features = SignalFeatures(observations)
        assert abs(features.doppler_spread - 0.9) < 0.01

    def test_to_vector_shape(self, observations):
        features = SignalFeatures(observations)
        vector = features.to_vector()
        assert vector.shape == (8,)

    def test_empty_observations(self):
        features = SignalFeatures([])
        assert features.snr_mean == 0.0
        assert features.snr_std == 0.0
        assert features.snr_min == 0.0
        assert features.snr_max == 0.0
        assert features.doppler_spread == 0.0


class TestFeatureExtractor:
    def test_extract_shape(self):
        extractor = FeatureExtractor()
        obs = [SignalObservation(GnssSource.GPS, 1, 45.0, 0.0, 0.0, 0.0, datetime.utcnow())]
        features = extractor.extract(obs)
        assert features.shape == (8,)

    def test_extract_batch_shape(self):
        extractor = FeatureExtractor()
        batch = [
            [SignalObservation(GnssSource.GPS, 1, 45.0, 0.0, 0.0, 0.0, datetime.utcnow())],
            [SignalObservation(GnssSource.GPS, 2, 40.0, 0.0, 0.0, 0.0, datetime.utcnow())],
        ]
        features = extractor.extract_batch(batch)
        assert features.shape == (2, 8)
