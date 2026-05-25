use gnss_parser::SignalObservation;

pub fn median_filter(observations: &[SignalObservation], window_size: usize) -> Vec<SignalObservation> {
    if observations.len() <= window_size {
        return observations.to_vec();
    }
    let mut filtered = Vec::with_capacity(observations.len());
    for i in 0..observations.len() {
        let start = if i >= window_size / 2 { i - window_size / 2 } else { 0 };
        let end = (i + window_size / 2 + 1).min(observations.len());
        let window = &observations[start..end];
        let mut snrs: Vec<f32> = window.iter().map(|o| o.snr_db_hz).collect();
        snrs.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        let median_snr = snrs[snrs.len() / 2];
        let mut obs = observations[i].clone();
        obs.snr_db_hz = median_snr;
        filtered.push(obs);
    }
    filtered
}

pub fn low_pass_filter(observations: &[SignalObservation], alpha: f32) -> Vec<SignalObservation> {
    if observations.is_empty() { return vec![]; }
    let mut filtered = Vec::with_capacity(observations.len());
    let mut prev_snr = observations[0].snr_db_hz;
    for obs in observations {
        let smoothed = alpha * obs.snr_db_hz + (1.0 - alpha) * prev_snr;
        let mut new_obs = obs.clone();
        new_obs.snr_db_hz = smoothed;
        filtered.push(new_obs);
        prev_snr = smoothed;
    }
    filtered
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_median_filter() {
        let obs: Vec<SignalObservation> = (0..10).map(|i| {
            SignalObservation::new(gnss_parser::GnssSource::Gps, 1, 40.0 + i as f32, 0.0, 0.0, 0.0, chrono::Utc::now().naive_utc())
        }).collect();
        let filtered = median_filter(&obs, 3);
        assert_eq!(filtered.len(), 10);
    }

    #[test]
    fn test_low_pass_filter() {
        let obs: Vec<SignalObservation> = (0..5).map(|i| {
            SignalObservation::new(gnss_parser::GnssSource::Gps, 1, 45.0 + (i as f32 * 10.0), 0.0, 0.0, 0.0, chrono::Utc::now().naive_utc())
        }).collect();
        let filtered = low_pass_filter(&obs, 0.5);
        assert_eq!(filtered.len(), 5);
    }
}
