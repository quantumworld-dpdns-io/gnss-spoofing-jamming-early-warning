pub mod circuits;
pub mod autoencoder;
pub mod vqc;
pub mod qrng;
pub mod integration;

use gnss_parser::SignalObservation;
use signal_processing::DetectionResult;

pub trait QuantumDetector: Send + Sync {
    fn name(&self) -> &str;
    fn detect_quantum(&self, features: &[f32]) -> DetectionResult;
    fn circuit_depth(&self) -> usize;
    fn requires_gpu(&self) -> bool;
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub enum QuantumBackend {
    QiskitAer,
    QiskitIBM,
    CUDAQ,
    PennyLane,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct QuantumConfig {
    pub backend: QuantumBackend,
    pub shots: u32,
    pub circuit_depth: usize,
    pub use_gpu: bool,
    pub ibm_token: Option<String>,
    pub ibm_instance: Option<String>,
}

impl Default for QuantumConfig {
    fn default() -> Self {
        Self {
            backend: QuantumBackend::QiskitAer,
            shots: 1024,
            circuit_depth: 4,
            use_gpu: false,
            ibm_token: None,
            ibm_instance: None,
        }
    }
}
