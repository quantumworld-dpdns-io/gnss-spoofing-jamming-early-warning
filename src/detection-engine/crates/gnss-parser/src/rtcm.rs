use crate::{GnssSource, SignalObservation, ParseError};

const RTCM_PREAMBLE: u8 = 0xD3;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct RtcmMessage {
    pub message_type: u16,
    pub station_id: u16,
    pub payload: Vec<u8>,
}

impl RtcmMessage {
    pub fn parse(data: &[u8]) -> Result<(Self, usize), ParseError> {
        if data.len() < 6 {
            return Err(ParseError::UnknownMessageType("frame too short".into()));
        }
        if data[0] != RTCM_PREAMBLE {
            return Err(ParseError::UnknownMessageType("invalid preamble".into()));
        }
        let _reserved = (data[1] >> 6) & 0x03;
        let length = ((data[1] as u16 & 0x3F) << 8) | data[2] as u16;
        let total_words = length + 3;
        let total_bytes = total_words as usize * 3;
        if data.len() < total_bytes {
            return Err(ParseError::UnknownMessageType("incomplete frame".into()));
        }
        let message_type = ((data[3] as u16) << 4) | ((data[4] >> 4) as u16);
        let station_id = ((data[4] as u16 & 0x0F) << 8) | data[5] as u16;
        let payload = data[6..total_bytes].to_vec();
        Ok((RtcmMessage { message_type, station_id, payload }, total_bytes))
    }

    pub fn to_observation(&self) -> Option<Vec<SignalObservation>> {
        match self.message_type {
            1001..=1004 => self.parse_gps_observations(),
            1071..=1077 => self.parse_gps_msm(),
            _ => None,
        }
    }

    fn parse_gps_observations(&self) -> Option<Vec<SignalObservation>> {
        if self.payload.len() < 8 { return None; }
        let timestamp = chrono::Utc::now().naive_utc();
        Some(vec![SignalObservation::new(
            GnssSource::Gps, 0, 0.0, 0.0, 0.0, 0.0, timestamp,
        )])
    }

    fn parse_gps_msm(&self) -> Option<Vec<SignalObservation>> {
        if self.payload.len() < 8 { return None; }
        let timestamp = chrono::Utc::now().naive_utc();
        Some(vec![SignalObservation::new(
            GnssSource::Gps, 0, 0.0, 0.0, 0.0, 0.0, timestamp,
        )])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rtcm_preamble_check() {
        let data = vec![0xD3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let (msg, size) = RtcmMessage::parse(&data).unwrap();
        assert_eq!(msg.message_type, 0);
        assert_eq!(size, 9);
    }

    #[test]
    fn test_invalid_preamble() {
        let data = vec![0x00; 10];
        assert!(RtcmMessage::parse(&data).is_err());
    }
}
