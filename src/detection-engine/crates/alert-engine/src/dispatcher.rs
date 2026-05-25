use crate::models::{Alert, AlertError};
use async_trait::async_trait;

#[async_trait]
pub trait AlertDispatcher: Send + Sync {
    async fn dispatch(&self, alert: &Alert) -> Result<(), AlertError>;
}

pub struct ConsoleDispatcher;

#[async_trait]
impl AlertDispatcher for ConsoleDispatcher {
    async fn dispatch(&self, alert: &Alert) -> Result<(), AlertError> {
        tracing::info!(
            alert_id = %alert.id,
            severity = ?alert.severity,
            rule = %alert.rule_name,
            "ALERT: {}",
            alert.description
        );
        Ok(())
    }
}

pub struct WebhookDispatcher {
    url: String,
    client: reqwest::Client,
}

impl WebhookDispatcher {
    pub fn new(url: String) -> Self {
        Self { url, client: reqwest::Client::new() }
    }
}

#[async_trait]
impl AlertDispatcher for WebhookDispatcher {
    async fn dispatch(&self, alert: &Alert) -> Result<(), AlertError> {
        let resp = self.client.post(&self.url)
            .json(alert)
            .send()
            .await
            .map_err(|e| AlertError::DispatchError(e.to_string()))?;
        if !resp.status().is_success() {
            return Err(AlertError::DispatchError(format!("HTTP {}", resp.status())));
        }
        Ok(())
    }
}

pub struct EmailDispatcher {
    smtp_server: String,
    recipients: Vec<String>,
}

impl EmailDispatcher {
    pub fn new(smtp_server: String, recipients: Vec<String>) -> Self {
        Self { smtp_server, recipients }
    }
}

#[async_trait]
impl AlertDispatcher for EmailDispatcher {
    async fn dispatch(&self, alert: &Alert) -> Result<(), AlertError> {
        tracing::info!("EMAIL to {:?}: {:?} - {}", self.recipients, alert.severity, alert.description);
        Ok(())
    }
}
