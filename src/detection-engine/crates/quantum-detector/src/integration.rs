use gnss_parser::SignalObservation;
use signal_processing::{DetectionResult, DetectorType};
use crate::QuantumConfig;

pub fn prepare_features(observations: &[SignalObservation]) -> Vec<Vec<f32>> {
    observations.chunks(8).map(|chunk| {
        chunk.iter().flat_map(|obs| {
            vec![
                obs.snr_db_hz / 60.0,
                obs.doppler_shift / 100.0,
                obs.pseudorange as f32 / 100000.0,
                obs.carrier_phase as f32 % 1.0,
            ]
        }).collect()
    }).collect()
}

pub fn run_quantum_pipeline(
    observations: &[SignalObservation],
    config: &QuantumConfig,
) -> Vec<DetectionResult> {
    let _features = prepare_features(observations);
    observations.iter().map(|obs| {
        DetectionResult {
            is_spoofed: false,
            confidence: 0.5,
            detector_type: DetectorType::QuantumAutoencoder,
            details: vec![format!("Quantum detection using {:?}", config.backend)],
            timestamp: obs.timestamp,
        }
    }).collect()
}
