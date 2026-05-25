use gnss_parser::SignalObservation;
use signal_processing::DetectionResult;
use signal_processing::DetectorType;

pub struct QuantumCircuit;

impl QuantumCircuit {
    pub fn angle_encoding(features: &[f32]) -> Vec<f32> {
        features.iter().map(|&f| f.atan() * 2.0 / std::f32::consts::PI).collect()
    }

    pub fn variational_ansatz(params: &[f32], n_qubits: usize) -> Vec<Vec<f32>> {
        params.chunks(n_qubits * 3).map(|chunk| chunk.to_vec()).collect()
    }

    pub fn kernel_estimate(x1: &[f32], x2: &[f32]) -> f32 {
        let dot: f32 = x1.iter().zip(x2.iter()).map(|(a, b)| a * b).sum();
        (dot / (x1.len() as f32)).abs()
    }
}

pub fn circuit_detection(observations: &[SignalObservation]) -> Vec<DetectionResult> {
    observations.iter().map(|obs| {
        let features = vec![obs.snr_db_hz / 60.0, obs.doppler_shift / 100.0];
        let encoded = QuantumCircuit::angle_encoding(&features);
        let score = QuantumCircuit::kernel_estimate(&encoded, &encoded);
        DetectionResult {
            is_spoofed: score > 0.5,
            confidence: score,
            detector_type: DetectorType::QuantumAutoencoder,
            details: vec![format!("Quantum circuit score: {:.4}", score)],
            timestamp: obs.timestamp,
        }
    }).collect()
}
