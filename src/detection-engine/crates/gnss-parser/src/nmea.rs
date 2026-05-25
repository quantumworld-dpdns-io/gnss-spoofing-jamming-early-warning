use crate::{GnssSource, SignalObservation, ParseError};
use nom::{
    bytes::complete::{take_while, take_while1},
    character::complete::{char, digit1, one_of},
    combinator::{map_res, opt, recognize},
    sequence::{preceded, terminated},
    IResult,
};
use std::str::FromStr;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct NmeaMessage {
    pub talker: String,
    pub sentence_type: String,
    pub fields: Vec<String>,
    pub raw: String,
}

impl NmeaMessage {
    pub fn parse(input: &str) -> Result<Self, ParseError> {
        let input = input.trim();
        if !input.starts_with('$') {
            return Err(ParseError::UnknownMessageType("missing $ prefix".into()));
        }
        let checksum_sep = input.rfind('*').ok_or_else(|| {
            ParseError::UnknownMessageType("missing checksum separator".into())
        })?;
        let (body, checksum_str) = input.split_at(checksum_sep);
        let body = &body[1..];
        let checksum_str = &checksum_str[1..];
        let calculated: u8 = body.bytes().fold(0, |acc, b| acc ^ b);
        let expected = u8::from_str_radix(checksum_str, 16)
            .map_err(|_| ParseError::UnknownMessageType("invalid checksum hex".into()))?;
        if calculated != expected {
            return Err(ParseError::ChecksumMismatch { expected, actual: calculated });
        }
        let parts: Vec<&str> = body.split(',').collect();
        if parts.len() < 2 {
            return Err(ParseError::InvalidFieldCount { expected: 2, actual: parts.len() });
        }
        let talker_sentence = parts[0];
        let talker = talker_sentence[..2].to_string();
        let sentence_type = talker_sentence[2..].to_string();
        let fields: Vec<String> = parts[1..].iter().map(|s| s.to_string()).collect();
        Ok(NmeaMessage { talker, sentence_type, fields, raw: input.to_string() })
    }

    pub fn to_observation(&self) -> Option<SignalObservation> {
        match self.sentence_type.as_str() {
            "GGA" => self.parse_gga(),
            "RMC" => self.parse_rmc(),
            "GSA" => self.parse_gsa(),
            "GSV" => self.parse_gsv(),
            _ => None,
        }
    }

    fn parse_gga(&self) -> Option<SignalObservation> {
        if self.fields.len() < 10 { return None; }
        let source = talker_to_source(&self.talker);
        let fields: Vec<&str> = self.fields.iter().map(|s| s.as_str()).collect();
        let _time_str = fields[0];
        let _lat = fields[1];
        let _lon = fields[3];
        let num_sats: u8 = fields[6].parse().ok()?;
        let timestamp = chrono::Utc::now().naive_utc();
        Some(SignalObservation::new(source, num_sats, 0.0, 0.0, 0.0, 0.0, timestamp))
    }

    fn parse_rmc(&self) -> Option<SignalObservation> {
        if self.fields.len() < 10 { return None; }
        let source = talker_to_source(&self.talker);
        let fields: Vec<&str> = self.fields.iter().map(|s| s.as_str()).collect();
        let _time_str = fields[0];
        let _status = fields[1];
        let _lat = fields[2];
        let _lon = fields[4];
        let speed_knots: f32 = fields[6].parse().unwrap_or(0.0);
        let _course: f32 = fields[7].parse().unwrap_or(0.0);
        let timestamp = chrono::Utc::now().naive_utc();
        Some(SignalObservation::new(source, 0, 0.0, 0.0, speed_knots as f64, _course, timestamp))
    }

    fn parse_gsa(&self) -> Option<SignalObservation> {
        if self.fields.len() < 17 { return None; }
        let source = talker_to_source(&self.talker);
        let fields: Vec<&str> = self.fields.iter().map(|s| s.as_str()).collect();
        let pdop: f32 = fields[14].parse().unwrap_or(0.0);
        let hdop: f32 = fields[15].parse().unwrap_or(0.0);
        let vdop: f32 = fields[16].parse().unwrap_or(0.0);
        let timestamp = chrono::Utc::now().naive_utc();
        Some(SignalObservation::new(source, 0, pdop, hdop as f64, vdop as f64, 0.0, timestamp))
    }

    fn parse_gsv(&self) -> Option<SignalObservation> {
        if self.fields.len() < 4 { return None; }
        let source = talker_to_source(&self.talker);
        let fields: Vec<&str> = self.fields.iter().map(|s| s.as_str()).collect();
        let _num_msgs: u8 = fields[0].parse().ok()?;
        let _msg_num: u8 = fields[1].parse().ok()?;
        let num_sats: u8 = fields[2].parse().ok()?;
        let timestamp = chrono::Utc::now().naive_utc();
        Some(SignalObservation::new(source, num_sats, 0.0, 0.0, 0.0, 0.0, timestamp))
    }
}

fn talker_to_source(talker: &str) -> GnssSource {
    match talker {
        "GP" => GnssSource::Gps,
        "GL" => GnssSource::Glonass,
        "GA" => GnssSource::Galileo,
        "GB" | "BD" => GnssSource::BeiDou,
        "QZ" => GnssSource::Qzss,
        "SB" => GnssSource::Sbas,
        _ => GnssSource::Unknown,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gga_parse() {
        let msg = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47";
        let parsed = NmeaMessage::parse(msg).unwrap();
        assert_eq!(parsed.talker, "GP");
        assert_eq!(parsed.sentence_type, "GGA");
        assert!(parsed.to_observation().is_some());
    }

    #[test]
    fn test_rmc_parse() {
        let msg = "$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A";
        let parsed = NmeaMessage::parse(msg).unwrap();
        assert_eq!(parsed.talker, "GP");
        assert_eq!(parsed.sentence_type, "RMC");
        assert!(parsed.to_observation().is_some());
    }

    #[test]
    fn test_checksum_error() {
        let msg = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*00";
        let result = NmeaMessage::parse(msg);
        assert!(result.is_err());
    }

    #[test]
    fn test_gsv_parse() {
        let msg = "$GPGSV,3,1,11,03,03,111,00,04,15,270,00,06,01,010,00,13,06,292,00*74";
        let parsed = NmeaMessage::parse(msg).unwrap();
        assert_eq!(parsed.sentence_type, "GSV");
        assert!(parsed.to_observation().is_some());
    }

    #[test]
    fn test_invalid_prefix() {
        let result = NmeaMessage::parse("GPGGA");
        assert!(result.is_err());
    }
}
