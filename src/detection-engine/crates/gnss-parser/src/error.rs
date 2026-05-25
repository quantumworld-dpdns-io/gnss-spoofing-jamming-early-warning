use thiserror::Error;

#[derive(Error, Debug)]
pub enum ParseError {
    #[error("checksum mismatch: expected {expected:#04x}, got {actual:#04x}")]
    ChecksumMismatch { expected: u8, actual: u8 },
    #[error("unknown message type: {0}")]
    UnknownMessageType(String),
    #[error("invalid field count: expected {expected}, got {actual}")]
    InvalidFieldCount { expected: usize, actual: usize },
    #[error("parse error: {0}")]
    NomError(String),
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
    #[error("utf8 error: {0}")]
    Utf8(#[from] std::str::Utf8Error),
}

impl From<nom::Err<nom::error::VerboseError<&[u8]>>> for ParseError {
    fn from(e: nom::Err<nom::error::VerboseError<&[u8]>>) -> Self {
        ParseError::NomError(e.to_string())
    }
}
