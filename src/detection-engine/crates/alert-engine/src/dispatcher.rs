use crate::models::{Alert, AlertError};
use std::future::Future;
use std::pin::Pin;

pub type DispatchResult = Pin<Box<dyn Future<Output = Result<(), AlertError>> + Send>>;

pub trait AlertDispatcher: Send + Sync {
    fn dispatch(&self, alert: &Alert) -> DispatchResult;
}

pub struct ConsoleDispatcher;

impl AlertDispatcher for ConsoleDispatcher {
    fn dispatch(&self, alert: &Alert) -> DispatchResult {
        let alert_id = alert.id.clone();
        let severity = alert.severity;
        let rule_name = alert.rule_name.clone();
        let description = alert.description.clone();
        Box::pin(async move {
            tracing::info!(
                alert_id = %alert_id,
                severity = ?severity,
                rule = %rule_name,
                "ALERT: {}",
                description
            );
            Ok(())
        })
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

impl AlertDispatcher for WebhookDispatcher {
    fn dispatch(&self, alert: &Alert) -> DispatchResult {
        let url = self.url.clone();
        let client = self.client.clone();
        let alert_data = alert.clone();
        Box::pin(async move {
            let resp = client.post(&url)
                .json(&alert_data)
                .send()
                .await
                .map_err(|e| AlertError::DispatchError(e.to_string()))?;
            if !resp.status().is_success() {
                return Err(AlertError::DispatchError(format!("HTTP {}", resp.status())));
            }
            Ok(())
        })
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

impl AlertDispatcher for EmailDispatcher {
    fn dispatch(&self, alert: &Alert) -> DispatchResult {
        let recipients = self.recipients.clone();
        let description = alert.description.clone();
        let severity = alert.severity;
        Box::pin(async move {
            tracing::info!("EMAIL to {:?}: {:?} - {}", recipients, severity, description);
            Ok(())
        })
    }
}
