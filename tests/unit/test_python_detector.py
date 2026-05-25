"""Unit tests for Python detection algorithms."""

import pytest
import numpy as np
from datetime import datetime
from gnss_core.detector import (
    CN0DeviationDetector,
    DopplerConsistencyDetector,
    CrossConstellationDetector,
    EnsembleDetector,
    DetectorType,
)
from gnss_core.models import SignalObservation, GnssSource


@pytest.fixture
def clean_observations():
    return [
        SignalObservation(GnssSource.GPS, 1, 45.0, 0.0, 0.0, 0.5, datetime.utcnow()),
        SignalObservation(GnssSource.GPS, 2, 44.0, 0.0, 0.0, 0.3, datetime.utcnow()),
        SignalObservation(GnssSource.GALILEO, 3, 46.0, 0.0, 0.0, 0.4, datetime.utcnow()),
    ]


@pytest.fixture
def spoofed_observations():
    return [
        SignalObservation(GnssSource.GPS, 1, 15.0, 0.0, 0.0, 50.0, datetime.utcnow()),
        SignalObservation(GnssSource.GPS, 2, 12.0, 0.0, 0.0, 60.0, datetime.utcnow()),
    ]


class TestCN0DeviationDetector:
    def test_detects_low_snr(self, spoofed_observations):
        detector = CN0DeviationDetector(threshold=30.0)
        results = detector.detect(spoofed_observations)
        assert all(r.is_spoofed for r in results)
        assert all(r.confidence > 0.8 for r in results)

    def test_passes_high_snr(self, clean_observations):
        detector = CN0DeviationDetector(threshold=30.0)
        results = detector.detect(clean_observations)
        assert not any(r.is_spoofed for r in results)

    def test_detector_type(self):
        detector = CN0DeviationDetector()
        assert detector.detector_type == DetectorType.CN0_DEVIATION
        assert detector.name == "C/N0 Deviation"


class TestDopplerConsistencyDetector:
    def test_detects_high_doppler(self, spoofed_observations):
        detector = DopplerConsistencyDetector(max_doppler_drift=10.0)
        results = detector.detect(spoofed_observations)
        assert all(r.is_spoofed for r in results)

    def test_passes_low_doppler(self, clean_observations):
        detector = DopplerConsistencyDetector(max_doppler_drift=10.0)
        results = detector.detect(clean_observations)
        assert not any(r.is_spoofed for r in results)


class TestCrossConstellationDetector:
    def test_detects_single_constellation(self):
        obs = [SignalObservation(GnssSource.GPS, 1, 45.0, 0.0, 0.0, 0.0, datetime.utcnow())]
        detector = CrossConstellationDetector(min_constellations=2)
        results = detector.detect(obs)
        assert results[0].is_spoofed

    def test_passes_multi_constellation(self, clean_observations):
        detector = CrossConstellationDetector(min_constellations=2)
        results = detector.detect(clean_observations)
        assert not results[0].is_spoofed


class TestEnsembleDetector:
    def test_ensemble_positive(self, spoofed_observations):
        detector = EnsembleDetector(ensemble_threshold=0.5)
        detector.add_detector(CN0DeviationDetector(threshold=30.0))
        detector.add_detector(DopplerConsistencyDetector(max_doppler_drift=10.0))
        results = detector.detect(spoofed_observations)
        assert results[0].is_spoofed

    def test_ensemble_negative(self, clean_observations):
        detector = EnsembleDetector(ensemble_threshold=0.5)
        detector.add_detector(CN0DeviationDetector(threshold=30.0))
        detector.add_detector(DopplerConsistencyDetector(max_doppler_drift=10.0))
        results = detector.detect(clean_observations)
        assert not results[0].is_spoofed
