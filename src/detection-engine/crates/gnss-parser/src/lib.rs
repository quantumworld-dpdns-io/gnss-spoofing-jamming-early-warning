pub mod nmea;
pub mod ubx;
pub mod rtcm;
pub mod error;

pub use error::ParseError;

pub trait GnssMessage: std::fmt::Debug + Send + Sync {
    fn talker_id(&self) -> &str;
    fn timestamp(&self) -> Option<chrono::NaiveDateTime>;
    fn source(&self) -> GnssSource;
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum GnssSource {
    Gps,
    Glonass,
    Galileo,
    BeiDou,
    Qzss,
    Sbas,
    Unknown,
}

impl GnssSource {
    pub fn from_identifier(id: u8) -> Self {
        match id {
            0 => GnssSource::Gps,
            1 => GnssSource::Glonass,
            2 => GnssSource::Galileo,
            3 => GnssSource::BeiDou,
            4 => GnssSource::Qzss,
            5 => GnssSource::Sbas,
            _ => GnssSource::Unknown,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SignalObservation {
    pub source: GnssSource,
    pub prn: u8,
    pub snr_db_hz: f32,
    pub carrier_phase: f64,
    pub pseudorange: f64,
    pub doppler_shift: f32,
    pub timestamp: chrono::NaiveDateTime,
    pub constellation: String,
}

impl SignalObservation {
    pub fn new(
        source: GnssSource,
        prn: u8,
        snr_db_hz: f32,
        carrier_phase: f64,
        pseudorange: f64,
        doppler_shift: f32,
        timestamp: chrono::NaiveDateTime,
    ) -> Self {
        let constellation = match source {
            GnssSource::Gps => "GPS".into(),
            GnssSource::Glonass => "GLONASS".into(),
            GnssSource::Galileo => "GALILEO".into(),
            GnssSource::BeiDou => "BEIDOU".into(),
            GnssSource::Qzss => "QZSS".into(),
            GnssSource::Sbas => "SBAS".into(),
            GnssSource::Unknown => "UNKNOWN".into(),
        };
        Self { source, prn, snr_db_hz, carrier_phase, pseudorange, doppler_shift, timestamp, constellation }
    }
}
