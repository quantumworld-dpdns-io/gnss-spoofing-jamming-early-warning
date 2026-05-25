"""Classical GNSS spoofing detection algorithms."""

from abc import ABC, abstractmethod
from collections import deque
from enum import Enum
from statistics import mean, stdev
from typing import Optional

from .models import SignalObservation, DetectionResult


class DetectorType(Enum):
    CN0_DEVIATION = "cn0_deviation"
    DOPPLER_CONSISTENCY = "doppler_consistency"
    CODE_CARRIER_DIVERGENCE = "code_carrier_divergence"
    CROSS_CONSTELLATION = "cross_constellation"
    ENSEMBLE = "ensemble"


class BaseDetector(ABC):
    @property
    @abstractmethod
    def name(self) -> str:
        ...

    @property
    @abstractmethod
    def detector_type(self) -> DetectorType:
        ...

    @abstractmethod
    def detect(self, observations: list[SignalObservation]) -> list[DetectionResult]:
        ...


class CN0DeviationDetector(BaseDetector):
    def __init__(self, window_size: int = 10, threshold: float = 30.0):
        self.window_size = window_size
        self.threshold = threshold
        self._history: deque[float] = deque(maxlen=window_size)

    @property
    def name(self) -> str:
        return "C/N0 Deviation"

    @property
    def detector_type(self) -> DetectorType:
        return DetectorType.CN0_DEVIATION

    def detect(self, observations: list[SignalObservation]) -> list[DetectionResult]:
        results = []
        for obs in observations:
            self._history.append(obs.snr_db_hz)
            is_spoofed = obs.snr_db_hz < self.threshold
            confidence = 0.85 if is_spoofed else 0.15
            snr_mean = mean(self._history) if self._history else 0.0
            results.append(DetectionResult(
                is_spoofed=is_spoofed,
                confidence=confidence,
                detector_type=self.detector_type.value,
                details=[f"C/N0: {obs.snr_db_hz:.1f} dB-Hz (mean: {snr_mean:.1f})"],
                timestamp=obs.timestamp,
            ))
        return results


class DopplerConsistencyDetector(BaseDetector):
    def __init__(self, max_doppler_drift: float = 5.0):
        self.max_doppler_drift = max_doppler_drift

    @property
    def name(self) -> str:
        return "Doppler Consistency"

    @property
    def detector_type(self) -> DetectorType:
        return DetectorType.DOPPLER_CONSISTENCY

    def detect(self, observations: list[SignalObservation]) -> list[DetectionResult]:
        results = []
        for obs in observations:
            drift = abs(obs.doppler_shift)
            is_spoofed = drift > self.max_doppler_drift
            results.append(DetectionResult(
                is_spoofed=is_spoofed,
                confidence=0.80 if is_spoofed else 0.20,
                detector_type=self.detector_type.value,
                details=[f"Doppler drift: {drift:.1f} Hz (max: {self.max_doppler_drift})"],
                timestamp=obs.timestamp,
            ))
        return results


class CrossConstellationDetector(BaseDetector):
    def __init__(self, min_constellations: int = 2):
        self.min_constellations = min_constellations

    @property
    def name(self) -> str:
        return "Cross-Constellation Check"

    @property
    def detector_type(self) -> DetectorType:
        return DetectorType.CROSS_CONSTELLATION

    def detect(self, observations: list[SignalObservation]) -> list[DetectionResult]:
        constellations = {obs.constellation for obs in observations}
        is_spoofed = len(constellations) < self.min_constellations
        return [DetectionResult(
            is_spoofed=is_spoofed,
            confidence=0.75 if is_spoofed else 0.25,
            detector_type=self.detector_type.value,
            details=[f"Constellations visible: {len(constellations)} (need >= {self.min_constellations})"],
        )]


class EnsembleDetector(BaseDetector):
    def __init__(self, detectors: Optional[list[BaseDetector]] = None,
                 ensemble_threshold: float = 0.7):
        self.detectors = detectors or []
        self.ensemble_threshold = ensemble_threshold

    @property
    def name(self) -> str:
        return "Ensemble Detector"

    @property
    def detector_type(self) -> DetectorType:
        return DetectorType.ENSEMBLE

    def add_detector(self, detector: BaseDetector) -> None:
        self.detectors.append(detector)

    def detect(self, observations: list[SignalObservation]) -> list[DetectionResult]:
        all_results: list[DetectionResult] = []
        for detector in self.detectors:
            all_results.extend(detector.detect(observations))
        positive = sum(1 for r in all_results if r.is_spoofed)
        total = len(all_results)
        confidence = positive / total if total > 0 else 0.0
        return [DetectionResult(
            is_spoofed=confidence >= self.ensemble_threshold,
            confidence=confidence,
            detector_type=self.detector_type.value,
            details=[f"Ensemble: {positive}/{total} detectors positive"],
        )]
