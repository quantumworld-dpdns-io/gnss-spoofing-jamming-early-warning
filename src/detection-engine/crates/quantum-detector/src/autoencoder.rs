use gnss_parser::SignalObservation;
use signal_processing::{DetectionResult, DetectorType};

pub struct HybridQuantumClassicalAutoencoder {
    pub input_dim: usize,
    pub latent_dim: usize,
    pub threshold: f32,
    encoder_weights: Vec<f32>,
    decoder_weights: Vec<f32>,
}

impl HybridQuantumClassicalAutoencoder {
    pub fn new(input_dim: usize, latent_dim: usize, threshold: f32) -> Self {
        let encoder_weights = vec![0.01; input_dim * latent_dim];
        let decoder_weights = vec![0.01; latent_dim * input_dim];
        Self { input_dim, latent_dim, threshold, encoder_weights, decoder_weights }
    }

    pub fn encode(&self, x: &[f32]) -> Vec<f32> {
        let mut z = vec![0.0; self.latent_dim];
        for i in 0..self.latent_dim {
            for j in 0..self.input_dim {
                z[i] += x[j] * self.encoder_weights[i * self.input_dim + j];
            }
        }
        z
    }

    pub fn decode(&self, z: &[f32]) -> Vec<f32> {
        let mut x_hat = vec![0.0; self.input_dim];
        for i in 0..self.input_dim {
            for j in 0..self.latent_dim {
                x_hat[i] += z[j] * self.decoder_weights[i * self.latent_dim + j];
            }
        }
        x_hat
    }

    pub fn reconstruction_error(&self, x: &[f32]) -> f32 {
        let z = self.encode(x);
        let x_hat = self.decode(&z);
        x.iter().zip(x_hat.iter()).map(|(a, b)| (a - b).powi(2)).sum::<f32>() / x.len() as f32
    }

    pub fn is_anomaly(&self, x: &[f32]) -> bool {
        self.reconstruction_error(x) > self.threshold
    }
}

pub fn autoencoder_detection(observations: &[SignalObservation]) -> Vec<DetectionResult> {
    let ae = HybridQuantumClassicalAutoencoder::new(4, 2, 0.1);
    observations.iter().map(|obs| {
        let features = vec![obs.snr_db_hz / 60.0, obs.doppler_shift / 100.0,
                            obs.pseudorange as f32 / 100000.0, obs.carrier_phase as f32 % 1.0];
        let error = ae.reconstruction_error(&features);
        let is_spoofed = ae.is_anomaly(&features);
        DetectionResult {
            is_spoofed,
            confidence: if is_spoofed { error.min(1.0) } else { 0.0 },
            detector_type: DetectorType::QuantumAutoencoder,
            details: vec![format!("HQC-AE reconstruction error: {:.6}", error)],
            timestamp: obs.timestamp,
        }
    }).collect()
}
