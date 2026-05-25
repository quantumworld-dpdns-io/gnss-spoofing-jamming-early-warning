"""Unit tests for data models."""

import pytest
from datetime import datetime
from gnss_core.models import SignalObservation, GnssSource, Alert, AlertSeverity, DetectionResult


class TestSignalObservation:
    def test_default_constellation(self):
        obs = SignalObservation(
            GnssSource.GPS, 1, 45.0, 0.0, 0.0, 0.0, datetime.utcnow()
        )
        assert obs.constellation == "GPS"

    def test_from_dict(self):
        data = {
            "source": "GALILEO",
            "prn": 3,
            "snr_db_hz": 46.0,
            "carrier_phase": 0.0,
            "pseudorange": 0.0,
            "doppler_shift": 0.4,
            "timestamp": "2026-01-01T12:00:00",
        }
        obs = SignalObservation.from_dict(data)
        assert obs.source == GnssSource.GALILEO
        assert obs.prn == 3
        assert obs.snr_db_hz == 46.0


class TestAlert:
    def test_auto_generates_uuid(self):
        alert = Alert(rule_name="test", severity=AlertSeverity.CRITICAL)
        assert len(alert.id) == 36

    def test_default_not_acknowledged(self):
        alert = Alert()
        assert not alert.acknowledged


class TestDetectionResult:
    def test_default_timestamp(self):
        result = DetectionResult(is_spoofed=True, confidence=0.9, detector_type="test")
        assert result.timestamp is not None

    def test_default_details_empty(self):
        result = DetectionResult(is_spoofed=False, confidence=0.1, detector_type="test")
        assert result.details == []
