pub mod detectors;
pub mod features;
pub mod filters;

use gnss_parser::SignalObservation;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DetectionResult {
    pub is_spoofed: bool,
    pub confidence: f32,
    pub detector_type: DetectorType,
    pub details: Vec<String>,
    pub timestamp: chrono::NaiveDateTime,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum DetectorType {
    CN0Deviation,
    DopplerConsistency,
    CodeCarrierDivergence,
    CrossConstellation,
    QuantumAutoencoder,
    QuantumVQC,
    MultiDetectorEnsemble,
}

pub trait Detector: Send + Sync {
    fn name(&self) -> &str;
    fn detect(&self, observations: &[SignalObservation]) -> Vec<DetectionResult>;
    fn detector_type(&self) -> DetectorType;
}
