use chrono::NaiveDateTime;
use serde::{Serialize, Deserialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Severity {
    Info,
    Warning,
    Critical,
}

impl Severity {
    pub fn level(&self) -> u8 {
        match self {
            Severity::Info => 0,
            Severity::Warning => 1,
            Severity::Critical => 2,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Alert {
    pub id: String,
    pub rule_name: String,
    pub severity: Severity,
    pub description: String,
    pub timestamp: NaiveDateTime,
    pub context: AlertContext,
    pub acknowledged: bool,
}

impl Alert {
    pub fn new(rule_name: String, severity: Severity, description: String, context: AlertContext) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            rule_name,
            severity,
            description,
            timestamp: chrono::Utc::now().naive_utc(),
            context,
            acknowledged: false,
        }
    }

    pub fn dedup_key(&self) -> String {
        format!("{}:{}", self.rule_name, self.context.location_id.clone().unwrap_or_default())
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct AlertContext {
    pub score: f32,
    pub location_id: Option<String>,
    pub constellation: Option<String>,
    pub prn: Option<u8>,
    pub metadata: HashMap<String, String>,
}

pub struct AlertRule {
    pub name: String,
    pub severity: Severity,
    pub description: String,
    evaluate: Box<dyn Fn(&AlertContext) -> bool + Send + Sync>,
}

impl AlertRule {
    pub fn new(
        name: String,
        severity: Severity,
        description: String,
        evaluate: Box<dyn Fn(&AlertContext) -> bool + Send + Sync>,
    ) -> Self {
        Self { name, severity, description, evaluate }
    }

    pub fn evaluate(&self, context: &AlertContext) -> bool {
        (self.evaluate)(context)
    }
}

#[derive(Debug, thiserror::Error)]
pub enum AlertError {
    #[error("dispatch error: {0}")]
    DispatchError(String),
    #[error("rate limited")]
    RateLimited,
}
