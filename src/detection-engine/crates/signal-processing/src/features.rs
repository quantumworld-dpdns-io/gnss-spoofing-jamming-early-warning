use gnss_parser::SignalObservation;
use ndarray::Array1;

pub struct SignalFeatures {
    pub snr_values: Vec<f32>,
    pub doppler_values: Vec<f32>,
    pub pseudorange_values: Vec<f64>,
    pub carrier_phase_values: Vec<f64>,
}

impl From<&[SignalObservation]> for SignalFeatures {
    fn from(observations: &[SignalObservation]) -> Self {
        let snr_values: Vec<f32> = observations.iter().map(|o| o.snr_db_hz).collect();
        let doppler_values: Vec<f32> = observations.iter().map(|o| o.doppler_shift).collect();
        let pseudorange_values: Vec<f64> = observations.iter().map(|o| o.pseudorange).collect();
        let carrier_phase_values: Vec<f64> = observations.iter().map(|o| o.carrier_phase).collect();
        Self { snr_values, doppler_values, pseudorange_values, carrier_phase_values }
    }
}

impl SignalFeatures {
    pub fn snr_mean(&self) -> f32 {
        if self.snr_values.is_empty() { return 0.0; }
        self.snr_values.iter().sum::<f32>() / self.snr_values.len() as f32
    }

    pub fn snr_std(&self) -> f32 {
        if self.snr_values.len() < 2 { return 0.0; }
        let mean = self.snr_mean();
        let variance = self.snr_values.iter().map(|v| (v - mean).powi(2)).sum::<f32>() / (self.snr_values.len() - 1) as f32;
        variance.sqrt()
    }

    pub fn snr_min(&self) -> f32 {
        self.snr_values.iter().cloned().fold(f32::MAX, f32::min)
    }

    pub fn snr_max(&self) -> f32 {
        self.snr_values.iter().cloned().fold(f32::MIN, f32::max)
    }

    pub fn doppler_spread(&self) -> f32 {
        if self.doppler_values.is_empty() { return 0.0; }
        let min = self.doppler_values.iter().cloned().fold(f32::MAX, f32::min);
        let max = self.doppler_values.iter().cloned().fold(f32::MIN, f32::max);
        (max - min).abs()
    }

    pub fn to_feature_vector(&self) -> Array1<f32> {
        Array1::from_vec(vec![
            self.snr_mean(),
            self.snr_std(),
            self.snr_min(),
            self.snr_max(),
            self.doppler_spread(),
            self.pseudorange_values.iter().map(|&v| v as f32).sum::<f32>() / self.pseudorange_values.len().max(1) as f32,
            self.carrier_phase_values.iter().map(|&v| v as f32).sum::<f32>() / self.carrier_phase_values.len().max(1) as f32,
        ])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_feature_extraction() {
        let obs = vec![
            SignalObservation::new(gnss_parser::GnssSource::Gps, 1, 45.0, 0.0, 0.0, 0.0, chrono::Utc::now().naive_utc()),
            SignalObservation::new(gnss_parser::GnssSource::Gps, 2, 40.0, 0.0, 0.0, 0.0, chrono::Utc::now().naive_utc()),
        ];
        let features: SignalFeatures = obs.as_slice().into();
        assert!((features.snr_mean() - 42.5).abs() < 0.01);
    }
}
