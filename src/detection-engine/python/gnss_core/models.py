"""Data models for GNSS signal observations and detection results."""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional


class GnssSource(Enum):
    GPS = "GPS"
    GLONASS = "GLONASS"
    GALILEO = "GALILEO"
    BEIDOU = "BEIDOU"
    QZSS = "QZSS"
    SBAS = "SBAS"
    UNKNOWN = "UNKNOWN"


class AlertSeverity(Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


@dataclass
class SignalObservation:
    source: GnssSource
    prn: int
    snr_db_hz: float
    carrier_phase: float
    pseudorange: float
    doppler_shift: float
    timestamp: datetime
    constellation: str = ""

    def __post_init__(self):
        if not self.constellation:
            self.constellation = self.source.value

    @classmethod
    def from_dict(cls, data: dict) -> "SignalObservation":
        return cls(
            source=GnssSource(data.get("source", "UNKNOWN")),
            prn=data.get("prn", 0),
            snr_db_hz=float(data.get("snr_db_hz", 0.0)),
            carrier_phase=float(data.get("carrier_phase", 0.0)),
            pseudorange=float(data.get("pseudorange", 0.0)),
            doppler_shift=float(data.get("doppler_shift", 0.0)),
            timestamp=datetime.fromisoformat(data.get("timestamp", datetime.utcnow().isoformat())),
        )


@dataclass
class DetectionResult:
    is_spoofed: bool
    confidence: float
    detector_type: str
    details: list[str] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.utcnow)


@dataclass
class Alert:
    id: str = ""
    rule_name: str = ""
    severity: AlertSeverity = AlertSeverity.INFO
    description: str = ""
    timestamp: datetime = field(default_factory=datetime.utcnow)
    context: dict = field(default_factory=dict)
    acknowledged: bool = False

    def __post_init__(self):
        if not self.id:
            import uuid
            self.id = str(uuid.uuid4())
