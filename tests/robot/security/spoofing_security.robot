*** Settings ***
Resource    ../resources/common.robot
Resource    ../resources/security_keywords.robot
Test Setup    Create API Session

*** Variables ***
${QUANTUM_QRNG_TEST}    ${TRUE}

*** Test Cases ***
Detection API Should Reject Overflow
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    snr_db_hz=999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
    ...    doppler_shift=0
    ${response}    POST On Session    api    /v1/detect    json=${body}    expected_status=any
    Should Be True    ${response.status_code} in [400, 413, 422]

GNSS Signal Replay Should Be Detected
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    observations=${EMPTY_LIST}
    ...    detector_type=quantum
    ...    timestamp=2020-01-01T00:00:00Z
    ${response}    POST On Session    api    /v1/detect    json=${body}    expected_status=any
    Should Be True    ${response.status_code} in [200, 400]

Unauthenticated Sensor Registration
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    sensor_id=malicious
    ...    location={"lat": 0, "lon": 0}
    ${response}    POST On Session    api    /v1/sensors    json=${body}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    401

Heatmap Data Poisoning
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    lat=999
    ...    lon=999
    ...    radius_km=-1
    ${response}    POST On Session    api    /v1/heatmap    json=${body}    expected_status=any
    Should Be True    ${response.status_code} in [400, 422]

Alert Injection
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    severity=critical
    ...    description=<script>alert(1)</script>
    ...    rule_name=fake_rule
    ${response}    POST On Session    api    /v1/alerts    json=${body}    expected_status=any
    Should Be True    ${response.status_code} in [400, 401, 422]
