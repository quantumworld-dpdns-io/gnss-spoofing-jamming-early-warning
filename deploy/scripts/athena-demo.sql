-- GNSS alert lake demo. Run inside the Athena workgroup created by Terraform.
-- Keep predicates tight: workgroup bytes_scanned_cutoff is 1 GiB.
SELECT event_id, severity, detector, received_at
FROM alert_events
WHERE severity IS NOT NULL
LIMIT 20;
