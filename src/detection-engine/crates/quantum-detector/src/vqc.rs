use gnss_parser::SignalObservation;
use signal_processing::{DetectionResult, DetectorType};

pub struct VariationalQuantumClassifier {
    pub n_qubits: usize,
    pub n_layers: usize,
    weights: Vec<f32>,
}

impl VariationalQuantumClassifier {
    pub fn new(n_qubits: usize, n_layers: usize) -> Self {
        let n_params = n_qubits * (n_layers + 1) * 3;
        let weights = vec![0.01; n_params];
        Self { n_qubits, n_layers, weights }
    }

    pub fn predict(&self, features: &[f32]) -> f32 {
        let encoded: Vec<f32> = features.iter().map(|&f| f.atan()).collect();
        let sum: f32 = encoded.iter().zip(self.weights.iter())
            .map(|(a, b)| a * b).sum();
        1.0 / (1.0 + (-sum).exp())
    }
}

pub fn vqc_detection(observations: &[SignalObservation]) -> Vec<DetectionResult> {
    let vqc = VariationalQuantumClassifier::new(4, 2);
    observations.iter().map(|obs| {
        let features = vec![obs.snr_db_hz / 60.0, obs.doppler_shift / 100.0,
                            obs.pseudorange as f32 / 100000.0, obs.carrier_phase as f32 % 1.0];
        let score = vqc.predict(&features);
        DetectionResult {
            is_spoofed: score > 0.5,
            confidence: score,
            detector_type: DetectorType::QuantumVQC,
            details: vec![format!("VQC score: {:.4}", score)],
            timestamp: obs.timestamp,
        }
    }).collect()
}
