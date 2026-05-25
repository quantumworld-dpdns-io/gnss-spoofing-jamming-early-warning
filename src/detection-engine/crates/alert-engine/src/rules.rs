use crate::models::{AlertContext, AlertRule, Severity};

pub fn default_rules() -> Vec<AlertRule> {
    vec![
        AlertRule::new(
            "high_spoofing_confidence".into(),
            Severity::Critical,
            "High-confidence spoofing detected by ensemble detector".into(),
            Box::new(|ctx: &AlertContext| ctx.score > 0.9),
        ),
        AlertRule::new(
            "medium_spoofing_confidence".into(),
            Severity::Warning,
            "Medium-confidence spoofing detected".into(),
            Box::new(|ctx: &AlertContext| ctx.score > 0.7 && ctx.score <= 0.9),
        ),
        AlertRule::new(
            "low_snr_anomaly".into(),
            Severity::Warning,
            "Abnormal C/N0 values detected across multiple satellites".into(),
            Box::new(|ctx: &AlertContext| ctx.score > 0.5 && ctx.score <= 0.7),
        ),
        AlertRule::new(
            "cross_constellation_mismatch".into(),
            Severity::Critical,
            "Position mismatch between GPS and Galileo constellations".into(),
            Box::new(|ctx: &AlertContext| {
                ctx.metadata.get("constellation_mismatch").map(|v| v == "true").unwrap_or(false)
            }),
        ),
        AlertRule::new(
            "quantum_detection_anomaly".into(),
            Severity::Critical,
            "Quantum autoencoder detected anomalous signal pattern".into(),
            Box::new(|ctx: &AlertContext| {
                ctx.score > 0.8 && ctx.metadata.get("detector_type")
                    .map(|v| v == "quantum").unwrap_or(false)
            }),
        ),
    ]
}
