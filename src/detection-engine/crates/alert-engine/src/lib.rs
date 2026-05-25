pub mod models;
pub mod dispatcher;
pub mod rules;

pub use models::*;
pub use dispatcher::*;
pub use rules::*;

use dashmap::DashMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::sync::broadcast;

pub struct AlertEngine {
    rules: Vec<AlertRule>,
    dispatchers: Vec<Box<dyn AlertDispatcher>>,
    alert_history: Arc<DashMap<String, Alert>>,
    tx: broadcast::Sender<Alert>,
    dedup_window_secs: u64,
}

impl AlertEngine {
    pub fn new(dedup_window_secs: u64) -> (Self, broadcast::Receiver<Alert>) {
        let (tx, rx) = broadcast::channel(1024);
        let engine = Self {
            rules: Vec::new(),
            dispatchers: Vec::new(),
            alert_history: Arc::new(DashMap::new()),
            tx,
            dedup_window_secs,
        };
        (engine, rx)
    }

    pub fn add_rule(&mut self, rule: AlertRule) {
        self.rules.push(rule);
    }

    pub fn add_dispatcher(&mut self, dispatcher: Box<dyn AlertDispatcher>) {
        self.dispatchers.push(dispatcher);
    }

    pub async fn evaluate(&self, context: &AlertContext) -> Vec<Alert> {
        let mut alerts = Vec::new();
        for rule in &self.rules {
            if rule.evaluate(context) {
                let alert = Alert::new(
                    rule.name.clone(),
                    rule.severity,
                    rule.description.clone(),
                    context.clone(),
                );
                if !self.is_duplicate(&alert) {
                    alerts.push(alert);
                }
            }
        }
        for alert in &alerts {
            let key = alert.dedup_key();
            self.alert_history.insert(key.clone(), alert.clone());
            let _ = self.tx.send(alert.clone());
            for dispatcher in &self.dispatchers {
                if let Err(e) = dispatcher.dispatch(alert).await {
                    tracing::error!("dispatch failed: {}", e);
                }
            }
        }
        alerts
    }

    fn is_duplicate(&self, alert: &Alert) -> bool {
        let key = alert.dedup_key();
        if let Some(existing) = self.alert_history.get(&key) {
            let age = chrono::Utc::now().naive_utc() - existing.timestamp;
            age.num_seconds() < self.dedup_window_secs as i64
        } else {
            false
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct TestDispatcher {
        called: Arc<AtomicBool>,
    }

    impl AlertDispatcher for TestDispatcher {
        fn dispatch(&self, alert: &Alert) -> dispatcher::DispatchResult {
            let called = self.called.clone();
            let _alert_id = alert.id.clone();
            Box::pin(async move {
                called.store(true, Ordering::SeqCst);
                Ok(())
            })
        }
    }

    #[tokio::test]
    async fn test_alert_engine_dispatch() {
        let (mut engine, _rx) = AlertEngine::new(60);
        let called = Arc::new(AtomicBool::new(false));
        engine.add_dispatcher(Box::new(TestDispatcher { called: called.clone() }));
        engine.add_rule(AlertRule::new(
            "test".into(), Severity::Warning, "test rule".into(),
            Box::new(|ctx: &AlertContext| ctx.score > 0.5),
        ));
        let ctx = AlertContext { score: 0.8, ..Default::default() };
        let alerts = engine.evaluate(&ctx).await;
        assert!(!alerts.is_empty());
        assert!(called.load(Ordering::SeqCst));
    }
}
