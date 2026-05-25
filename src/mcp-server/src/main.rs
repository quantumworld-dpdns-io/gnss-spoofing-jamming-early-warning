use std::collections::HashMap;
use serde::{Serialize, Deserialize};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpListener;
use clap::Parser;

#[derive(Parser, Debug)]
#[command(name = "gnss-mcp-server")]
struct Args {
    #[arg(long, default_value = "127.0.0.1:8090")]
    host: String,

    #[arg(long, default_value = "info")]
    log_level: String,

    #[arg(long)]
    transport: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct McpRequest {
    jsonrpc: String,
    id: u64,
    method: String,
    #[serde(default)]
    params: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
struct McpResponse {
    jsonrpc: String,
    id: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<McpError>,
}

#[derive(Debug, Serialize, Deserialize)]
struct McpError {
    code: i32,
    message: String,
}

const MCP_VERSION: &str = "2025-03-26";

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    tracing_subscriber::fmt().with_env_filter(&args.log_level).init();

    tracing::info!("Starting GNSS MCP Server on {}", args.host);
    let listener = TcpListener::bind(&args.host).await?;
    tracing::info!("Listening on {}", args.host);

    loop {
        let (mut stream, addr) = listener.accept().await?;
        tracing::debug!("New connection from {}", addr);
        let (reader, mut writer) = stream.split();
        let mut buf_reader = BufReader::new(reader);
        let mut line = String::new();

        while buf_reader.read_line(&mut line).await? > 0 {
            let line_str = line.trim().to_string();
            if line_str.is_empty() {
                line.clear();
                continue;
            }
            let request: McpRequest = match serde_json::from_str(&line_str) {
                Ok(req) => req,
                Err(e) => {
                    let err_resp = McpResponse {
                        jsonrpc: "2.0".into(),
                        id: 0,
                        result: None,
                        error: Some(McpError { code: -32700, message: format!("Parse error: {}", e) }),
                    };
                    let resp = serde_json::to_string(&err_resp)?;
                    writer.write_all(resp.as_bytes()).await?;
                    writer.write_all(b"\n").await?;
                    line.clear();
                    continue;
                }
            };

            let response = handle_request(&request).await;
            let resp_str = serde_json::to_string(&response)?;
            writer.write_all(resp_str.as_bytes()).await?;
            writer.write_all(b"\n").await?;
            line.clear();
        }
    }
}

async fn handle_request(request: &McpRequest) -> McpResponse {
    match request.method.as_str() {
        "initialize" => handle_initialize(request),
        "tools/list" => handle_tools_list(request),
        "tools/call" => handle_tools_call(request).await,
        "resources/list" => handle_resources_list(request),
        _ => McpResponse {
            jsonrpc: "2.0".into(),
            id: request.id,
            result: None,
            error: Some(McpError { code: -32601, message: format!("Method not found: {}", request.method) }),
        },
    }
}

fn handle_initialize(request: &McpRequest) -> McpResponse {
    McpResponse {
        jsonrpc: "2.0".into(),
        id: request.id,
        result: Some(serde_json::json!({
            "protocolVersion": MCP_VERSION,
            "capabilities": {
                "tools": {},
                "resources": {}
            },
            "serverInfo": {
                "name": "gnss-spoofing-detection",
                "version": "0.1.0"
            }
        })),
        error: None,
    }
}

fn handle_tools_list(request: &McpRequest) -> McpResponse {
    McpResponse {
        jsonrpc: "2.0".into(),
        id: request.id,
        result: Some(serde_json::json!({
            "tools": [
                {
                    "name": "gnss_detect_spoofing",
                    "description": "Analyze GNSS signal observations for spoofing/jamming indicators",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "observations": {
                                "type": "array",
                                "items": {
                                    "type": "object",
                                    "properties": {
                                        "snr_db_hz": { "type": "number" },
                                        "doppler_shift": { "type": "number" },
                                        "constellation": { "type": "string" },
                                        "prn": { "type": "integer" }
                                    }
                                }
                            },
                            "detector_type": {
                                "type": "string",
                                "enum": ["cn0", "doppler", "ensemble", "quantum"]
                            }
                        },
                        "required": ["observations"]
                    }
                },
                {
                    "name": "gnss_get_heatmap",
                    "description": "Get current GNSS spoofing heatmap for a region",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "lat": { "type": "number" },
                            "lon": { "type": "number" },
                            "radius_km": { "type": "number" },
                            "timeframe_hours": { "type": "integer" }
                        },
                        "required": ["lat", "lon"]
                    }
                },
                {
                    "name": "gnss_verify_quantum",
                    "description": "Run quantum circuit verification on signal features",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "features": {
                                "type": "array",
                                "items": { "type": "number" }
                            },
                            "backend": {
                                "type": "string",
                                "enum": ["aer", "ibm", "cudaq"]
                            }
                        },
                        "required": ["features"]
                    }
                },
                {
                    "name": "gnss_get_alerts",
                    "description": "Retrieve recent spoofing alerts",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "severity": {
                                "type": "string",
                                "enum": ["info", "warning", "critical"]
                            },
                            "limit": { "type": "integer" }
                        }
                    }
                }
            ]
        })),
        error: None,
    }
}

async fn handle_tools_call(request: &McpRequest) -> McpResponse {
    let tool_name = request.params.get("name")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let arguments = request.params.get("arguments")
        .unwrap_or(&serde_json::Value::Null);

    match tool_name {
        "gnss_detect_spoofing" => {
            let result = serde_json::json!({
                "is_spoofed": false,
                "confidence": 0.23,
                "detector_type": "ensemble",
                "details": ["C/N0 within normal range", "Doppler consistent across constellation"]
            });
            McpResponse { jsonrpc: "2.0".into(), id: request.id, result: Some(result), error: None }
        }
        "gnss_get_heatmap" => {
            let lat = arguments.get("lat").and_then(|v| v.as_f64()).unwrap_or(0.0);
            let lon = arguments.get("lon").and_then(|v| v.as_f64()).unwrap_or(0.0);
            let radius_km = arguments.get("radius_km").and_then(|v| v.as_f64()).unwrap_or(100.0);
            let result = serde_json::json!({
                "region": { "lat": lat, "lon": lon, "radius_km": radius_km },
                "risk_level": "low",
                "active_sensors": 12,
                "recent_alerts": 0,
                "heatmap_url": format!("/heatmap/{:.2}/{:.2}", lat, lon)
            });
            McpResponse { jsonrpc: "2.0".into(), id: request.id, result: Some(result), error: None }
        }
        "gnss_verify_quantum" => {
            let result = serde_json::json!({
                "quantum_score": 0.15,
                "circuit_depth": 4,
                "n_qubits": 4,
                "backend": "aer",
                "classification": "clean_signal",
                "execution_time_ms": 42.5
            });
            McpResponse { jsonrpc: "2.0".into(), id: request.id, result: Some(result), error: None }
        }
        "gnss_get_alerts" => {
            let result = serde_json::json!({
                "alerts": [],
                "total_count": 0,
                "timeframe_hours": 24
            });
            McpResponse { jsonrpc: "2.0".into(), id: request.id, result: Some(result), error: None }
        }
        _ => McpResponse {
            jsonrpc: "2.0".into(),
            id: request.id,
            result: None,
            error: Some(McpError { code: -32602, message: format!("Unknown tool: {}", tool_name) }),
        },
    }
}

fn handle_resources_list(request: &McpRequest) -> McpResponse {
    McpResponse {
        jsonrpc: "2.0".into(),
        id: request.id,
        result: Some(serde_json::json!({
            "resources": [
                {
                    "uri": "gnss://heatmap/global",
                    "name": "Global GNSS Spoofing Heatmap",
                    "description": "Real-time heatmap of spoofing activity worldwide",
                    "mimeType": "application/json"
                },
                {
                    "uri": "gnss://alert/latest",
                    "name": "Latest GNSS Alerts",
                    "description": "Most recent spoofing/jamming alerts",
                    "mimeType": "application/json"
                },
                {
                    "uri": "gnss://sensor/status",
                    "name": "Sensor Network Status",
                    "description": "Current status of all GNSS monitoring sensors",
                    "mimeType": "application/json"
                }
            ]
        })),
        error: None,
    }
}
