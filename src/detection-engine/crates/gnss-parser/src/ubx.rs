use crate::{GnssSource, SignalObservation, ParseError};
use bytes::{Bytes, Buf};
use chrono::NaiveDateTime;

pub const UBX_SYNC_CHAR_1: u8 = 0xB5;
pub const UBX_SYNC_CHAR_2: u8 = 0x62;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct UbxFrame {
    pub class: u8,
    pub id: u8,
    pub length: u16,
    pub payload: Bytes,
}

impl UbxFrame {
    pub fn parse(data: &[u8]) -> Result<(Self, usize), ParseError> {
        if data.len() < 8 {
            return Err(ParseError::UnknownMessageType("frame too short".into()));
        }
        if data[0] != UBX_SYNC_CHAR_1 || data[1] != UBX_SYNC_CHAR_2 {
            return Err(ParseError::UnknownMessageType("invalid sync chars".into()));
        }
        let class = data[2];
        let id = data[3];
        let length = u16::from_le_bytes([data[4], data[5]]);
        let total_len = 8 + length as usize;
        if data.len() < total_len {
            return Err(ParseError::UnknownMessageType("incomplete frame".into()));
        }
        let payload = Bytes::copy_from_slice(&data[6..6 + length as usize]);
        let ck_a = data[6 + length as usize];
        let ck_b = data[6 + length as usize + 1];
        let mut calc_a: u8 = 0;
        let mut calc_b: u8 = 0;
        for &b in &data[2..6 + length as usize] {
            calc_a = calc_a.wrapping_add(b);
            calc_b = calc_b.wrapping_add(calc_a);
        }
        if calc_a != ck_a || calc_b != ck_b {
            return Err(ParseError::ChecksumMismatch { expected: ck_a, actual: calc_a });
        }
        Ok((UbxFrame { class, id, length, payload }, total_len))
    }

    pub fn to_observation(&self) -> Option<Vec<SignalObservation>> {
        match (self.class, self.id) {
            (0x01, 0x02) => self.parse_nav_posllh(),
            (0x01, 0x07) => self.parse_nav_pvt(),
            _ => None,
        }
    }

    fn parse_nav_posllh(&self) -> Option<Vec<SignalObservation>> {
        if self.payload.len() < 28 { return None; }
        let mut buf = self.payload.clone();
        let _itow = buf.get_u32_le();
        let _lon = buf.get_i32_le();
        let _lat = buf.get_i32_le();
        let _height = buf.get_i32_le();
        let _hmsl = buf.get_i32_le();
        let _hacc = buf.get_u32_le();
        let _vacc = buf.get_u32_le();
        let timestamp = chrono::Utc::now().naive_utc();
        Some(vec![SignalObservation::new(
            GnssSource::Unknown, 0, 0.0, 0.0, 0.0, 0.0, timestamp,
        )])
    }

    fn parse_nav_pvt(&self) -> Option<Vec<SignalObservation>> {
        if self.payload.len() < 92 { return None; }
        let mut buf = self.payload.clone();
        let _itow = buf.get_u32_le();
        let _year = buf.get_u16_le();
        let _month = buf.get_u8();
        let _day = buf.get_u8();
        let _hour = buf.get_u8();
        let _min = buf.get_u8();
        let _sec = buf.get_u8();
        let _valid = buf.get_u8();
        let _tacc = buf.get_u32_le();
        let _nano = buf.get_i32_le();
        let _fix_type = buf.get_u8();
        let _flags = buf.get_u8();
        let _flags2 = buf.get_u8();
        let _num_svs = buf.get_u8();
        let _lon = buf.get_i32_le();
        let _lat = buf.get_i32_le();
        let _height = buf.get_i32_le();
        let _hmsl = buf.get_i32_le();
        let _hacc = buf.get_u32_le();
        let _vacc = buf.get_u32_le();
        let _veln = buf.get_i32_le();
        let _vele = buf.get_i32_le();
        let _veld = buf.get_i32_le();
        let _gspeed = buf.get_i32_le();
        let _head_mot = buf.get_i32_le();
        let _sacc = buf.get_u32_le();
        let _head_acc = buf.get_u32_le();
        let _pdop = buf.get_u16_le();
        let _flags3 = buf.get_u16_le();
        let timestamp = chrono::Utc::now().naive_utc();
        Some(vec![SignalObservation::new(
            GnssSource::Unknown, _num_svs, _sacc as f32 / 1000.0, 0.0,
            _gspeed as f64 / 1000.0, 0.0, timestamp,
        )])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ubx_sync_check() {
        let payload: [u8; 0] = [];
        let ck_a: u8 = payload.iter().fold(0x01u8.wrapping_add(0x02), |a, &b| a.wrapping_add(b));
        let ck_b: u8 = payload.iter().fold(ck_a, |a, &b| a.wrapping_add(b));
        let mut data = vec![0xB5, 0x62, 0x01, 0x02, 0x00, 0x00, ck_a, ck_b];
        let (frame, size) = UbxFrame::parse(&data).unwrap();
        assert_eq!(frame.class, 0x01);
        assert_eq!(frame.id, 0x02);
        assert_eq!(size, 8);
    }

    #[test]
    fn test_invalid_sync() {
        let data = vec![0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x00];
        assert!(UbxFrame::parse(&data).is_err());
    }
}
