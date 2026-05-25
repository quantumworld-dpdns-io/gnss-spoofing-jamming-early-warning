use crate::{DetectionResult, Detector, DetectorType};
use gnss_parser::SignalObservation;
use std::collections::VecDeque;

pub struct CN0DeviationDetector {
    window_size: usize,
    threshold: f32,
    history: VecDeque<f32>,
    name: String,
}

impl CN0DeviationDetector {
    pub fn new(window_size: usize, threshold: f32) -> Self {
        Self { window_size, threshold, history: VecDeque::with_capacity(window_size), name: "C/N0 Deviation".into() }
    }
}

impl Detector for CN0DeviationDetector {
    fn name(&self) -> &str { &self.name }

    fn detector_type(&self) -> DetectorType { DetectorType::CN0Deviation }

    fn detect(&self, observations: &[SignalObservation]) -> Vec<DetectionResult> {
        observations.iter().map(|obs| {
            let is_spoofed = obs.snr_db_hz > 0.0 && obs.snr_db_hz < self.threshold;
            DetectionResult {
                is_spoofed,
                confidence: if is_spoofed { 0.85 } else { 0.15 },
                detector_type: self.detector_type(),
                details: vec![format!("C/N0: {:.1} dB-Hz (threshold: {:.1})", obs.snr_db_hz, self.threshold)],
                timestamp: obs.timestamp,
            }
        }).collect()
    }
}

pub struct DopplerConsistencyDetector {
    max_doppler_drift: f32,
    name: String,
}

impl DopplerConsistencyDetector {
    pub fn new(max_doppler_drift: f32) -> Self {
        Self { max_doppler_drift, name: "Doppler Consistency".into() }
    }
}

impl Detector for DopplerConsistencyDetector {
    fn name(&self) -> &str { &self.name }
    fn detector_type(&self) -> DetectorType { DetectorType::DopplerConsistency }

    fn detect(&self, observations: &[SignalObservation]) -> Vec<DetectionResult> {
        observations.iter().map(|obs| {
            let drift = obs.doppler_shift.abs();
            let is_spoofed = drift > self.max_doppler_drift;
            DetectionResult {
                is_spoofed,
                confidence: if is_spoofed { 0.80 } else { 0.20 },
                detector_type: self.detector_type(),
                details: vec![format!("Doppler drift: {:.1} Hz (max: {:.1})", drift, self.max_doppler_drift)],
                timestamp: obs.timestamp,
            }
        }).collect()
    }
}

pub struct CrossConstellationDetector {
    max_position_deviation_m: f32,
    name: String,
}

impl CrossConstellationDetector {
    pub fn new(max_position_deviation_m: f32) -> Self {
        Self { max_position_deviation_m, name: "Cross-Constellation Check".into() }
    }
}

impl Detector for CrossConstellationDetector {
    fn name(&self) -> &str { &self.name }
    fn detector_type(&self) -> DetectorType { DetectorType::CrossConstellation }

    fn detect(&self, observations: &[SignalObservation]) -> Vec<DetectionResult> {
        let constellations: std::collections::HashSet<String> =
            observations.iter().map(|o| o.constellation.clone()).collect();
        let unique_sources = constellations.len();
        let is_spoofed = unique_sources < 2;
        vec![DetectionResult {
            is_spoofed,
            confidence: if is_spoofed { 0.75 } else { 0.25 },
            detector_type: self.detector_type(),
            details: vec![format!("Constellations visible: {} (need >= 2)", unique_sources)],
            timestamp: chrono::Utc::now().naive_utc(),
        }]
    }
}

pub struct EnsembleDetector {
    detectors: Vec<Box<dyn Detector>>,
    ensemble_threshold: f32,
    name: String,
}

impl EnsembleDetector {
    pub fn new(detectors: Vec<Box<dyn Detector>>, ensemble_threshold: f32) -> Self {
        Self { detectors, ensemble_threshold, name: "Ensemble Detector".into() }
    }
}

impl Detector for EnsembleDetector {
    fn name(&self) -> &str { &self.name }
    fn detector_type(&self) -> DetectorType { DetectorType::MultiDetectorEnsemble }

    fn detect(&self, observations: &[SignalObservation]) -> Vec<DetectionResult> {
        let mut all_results: Vec<DetectionResult> = Vec::new();
        for detector in &self.detectors {
            all_results.extend(detector.detect(observations));
        }
        let positive_count = all_results.iter().filter(|r| r.is_spoofed).count();
        let total = all_results.len();
        let ensemble_confidence = if total > 0 { positive_count as f32 / total as f32 } else { 0.0 };
        let is_spoofed = ensemble_confidence >= self.ensemble_threshold;
        let details: Vec<String> = all_results.iter().map(|r| format!("{}: {}", r.detector_type.as_ref(), r.confidence)).collect();
        vec![DetectionResult {
            is_spoofed,
            confidence: ensemble_confidence,
            detector_type: self.detector_type(),
            details,
            timestamp: chrono::Utc::now().naive_utc(),
        }]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cn0_detector_flags_low_snr() {
        let det = CN0DeviationDetector::new(10, 30.0);
        let obs = SignalObservation::new(
            gnss_parser::GnssSource::Gps, 1, 25.0, 0.0, 0.0, 0.0,
            chrono::Utc::now().naive_utc(),
        );
        let results = det.detect(&[obs]);
        assert!(results[0].is_spoofed);
    }

    #[test]
    fn test_doppler_detector_high_drift() {
        let det = DopplerConsistencyDetector::new(5.0);
        let obs = SignalObservation::new(
            gnss_parser::GnssSource::Gps, 1, 45.0, 0.0, 0.0, 100.0,
            chrono::Utc::now().naive_utc(),
        );
        let results = det.detect(&[obs]);
        assert!(results[0].is_spoofed);
    }
}

impl std::fmt::Display for DetectorType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DetectorType::CN0Deviation => write!(f, "C/N0 Deviation"),
            DetectorType::DopplerConsistency => write!(f, "Doppler Consistency"),
            DetectorType::CodeCarrierDivergence => write!(f, "Code-Carrier Divergence"),
            DetectorType::CrossConstellation => write!(f, "Cross-Constellation"),
            DetectorType::QuantumAutoencoder => write!(f, "Quantum Autoencoder"),
            DetectorType::QuantumVQC => write!(f, "Quantum VQC"),
            DetectorType::MultiDetectorEnsemble => write!(f, "Ensemble"),
        }
    }
}

impl AsRef<str> for DetectorType {
    fn as_ref(&self) -> &str {
        match self {
            DetectorType::CN0Deviation => "cn0_deviation",
            DetectorType::DopplerConsistency => "doppler_consistency",
            DetectorType::CodeCarrierDivergence => "code_carrier_divergence",
            DetectorType::CrossConstellation => "cross_constellation",
            DetectorType::QuantumAutoencoder => "quantum_autoencoder",
            DetectorType::QuantumVQC => "quantum_vqc",
            DetectorType::MultiDetectorEnsemble => "ensemble",
        }
    }
}
