*** Settings ***
Resource    ../resources/common.robot
Test Setup    Create API Session

*** Test Cases ***
Health Endpoint Returns OK
    ${response}    GET On Session    api    /v1/health
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Should Be Equal    ${json}[status]    ok
    Should Be Equal    ${json}[version]    0.1.0

Detection Endpoint Accepts POST
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    observations=${EMPTY_LIST}
    ...    detector_type=ensemble
    ${response}    POST On Session    api    /v1/detect    json=${body}
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}    is_spoofed
    Dictionary Should Contain Key    ${json}    confidence

Heatmap Endpoint Returns Data
    ${params}    Create Dictionary    lat=25.0330    lon=121.5654    radius_km=50
    ${response}    GET On Session    api    /v1/heatmap    params=${params}
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}    risk_level

Alerts Endpoint Returns List
    ${response}    GET On Session    api    /v1/alerts
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}    alerts
    Dictionary Should Contain Key    ${json}    total_count

Sensors Endpoint Returns List
    ${response}    GET On Session    api    /v1/sensors
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}    sensors

MCP Tools List Endpoint
    Create MCP Session
    ${body}    Create Dictionary
    ...    jsonrpc=2.0
    ...    id=1
    ...    method=tools/list
    ${response}    POST On Session    mcp    /    json=${body}
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}    result
    Dictionary Should Contain Key    ${json}[result]    tools

MCP Detect Spoofing Tool
    Create MCP Session
    ${body}    Create Dictionary
    ...    jsonrpc=2.0
    ...    id=2
    ...    method=tools/call
    ...    params={"name": "gnss_detect_spoofing", "arguments": {"observations": [{"snr_db_hz": 45.0}]}}
    ${response}    POST On Session    mcp    /    json=${body}
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}[result]    is_spoofed

MCP Get Heatmap Tool
    Create MCP Session
    ${body}    Create Dictionary
    ...    jsonrpc=2.0
    ...    id=3
    ...    method=tools/call
    ...    params={"name": "gnss_get_heatmap", "arguments": {"lat": 25.0330, "lon": 121.5654}}
    ${response}    POST On Session    mcp    /    json=${body}
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}[result]    risk_level

MCP Quantum Verify Tool
    Create MCP Session
    ${body}    Create Dictionary
    ...    jsonrpc=2.0
    ...    id=4
    ...    method=tools/call
    ...    params={"name": "gnss_verify_quantum", "arguments": {"features": [0.5, 0.3, 0.8, 0.1]}}
    ${response}    POST On Session    mcp    /    json=${body}
    Should Be Equal As Integers    ${response.status_code}    200
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}[result]    quantum_score
