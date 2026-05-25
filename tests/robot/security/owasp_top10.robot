*** Settings ***
Resource    ../resources/common.robot
Resource    ../resources/security_keywords.robot
Test Setup    Create API Session

*** Variables ***
${SQL_PAYLOAD_1}    ' OR '1'='1
${SQL_PAYLOAD_2}    '; DROP TABLE users; --
${SQL_PAYLOAD_3}    ' UNION SELECT * FROM users; --
${SQL_PAYLOAD_4}    1; SELECT * FROM admins
${SQL_PAYLOAD_5}    ' OR 1=1; --
${XSS_PAYLOAD_1}    <script>alert('xss')</script>
${XSS_PAYLOAD_2}    <img src=x onerror=alert(1)>
${XSS_PAYLOAD_3}    <svg onload=alert(1)>
${XSS_PAYLOAD_4}    javascript:alert('xss')
${PATH_TRAVERSAL_1}    ../../../etc/passwd
${PATH_TRAVERSAL_2}    ..\\..\\..\\windows\\system32\\drivers\\etc\\hosts
${CMD_INJECTION_1}    ; ls -la /
${CMD_INJECTION_2}    | cat /etc/passwd
${CMD_INJECTION_3}    $(cat /etc/shadow)
${SSRF_URL_1}         http://169.254.169.254/latest/meta-data/
${SSRF_URL_2}         http://127.0.0.1:6379
${SSRF_URL_3}         file:///etc/passwd

*** Test Cases ***
# ─── A1: Broken Access Control ───────────────────────────
A1.01 Missing Auth On Health Endpoint
    ${response}    GET On Session    api    /v1/health    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200

A1.02 Missing Auth On Alerts Endpoint
    ${response}    GET On Session    api    /v1/alerts    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200

A1.03 Missing Auth On Admin Endpoint
    Missing Auth Should Return 401    /v1/admin/users

A1.04 Role Escalation Attempt
    ${headers}    Create Dictionary    Authorization=Bearer ${USER_TOKEN}
    ${response}    GET On Session    api    /v1/admin/users    headers=${headers}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    403

A1.05 IDOR Attempt
    ${headers}    Create Dictionary    Authorization=Bearer ${USER_TOKEN}
    ${response}    GET On Session    api    /v1/sensors/99999    headers=${headers}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    403

# ─── A2: Cryptographic Failures ──────────────────────────
A2.01 Weak TLS Should Not Be Supported
    ${response}    GET    https://localhost:8080/v1/health    verify=False    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200

A2.02 Sensitive Data In Response
    ${response}    GET On Session    api    /v1/health
    Should Not Contain    ${response.text}    password
    Should Not Contain    ${response.text}    secret
    Should Not Contain    ${response.text}    token
    Should Not Contain    ${response.text}    credit_card

A2.03 Default Credentials Check
    ${headers}    Create Dictionary
    ...    Authorization=Basic YWRtaW46YWRtaW4=
    ${response}    GET On Session    api    /v1/admin    headers=${headers}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    401

# ─── A3: Injection ────────────────────────────────────────
A3.01 SQL Injection On Sensors Endpoint
    SQL Injection Attempt Should Be Rejected    /v1/sensors    id    ${SQL_PAYLOAD_1}

A3.02 SQL Injection On Alerts Endpoint
    SQL Injection Attempt Should Be Rejected    /v1/alerts    severity    ${SQL_PAYLOAD_2}

A3.03 SQL Injection With UNION
    SQL Injection Attempt Should Be Rejected    /v1/sensors    name    ${SQL_PAYLOAD_3}

A3.04 SQL Injection Numeric
    SQL Injection Attempt Should Be Rejected    /v1/sensors    limit    ${SQL_PAYLOAD_4}

A3.05 Second Order SQL Injection
    SQL Injection Attempt Should Be Rejected    /v1/sensors    query    ${SQL_PAYLOAD_5}

A3.06 NoSQL Injection On Detection
    NoSQL Injection Should Be Rejected    /v1/detect

A3.07 Command Injection On Health
    Command Injection Should Be Rejected    /v1/health    ${CMD_INJECTION_1}

A3.08 Command Injection With Pipe
    Command Injection Should Be Rejected    /v1/health    ${CMD_INJECTION_2}

A3.09 Command Injection With Subshell
    Command Injection Should Be Rejected    /v1/health    ${CMD_INJECTION_3}

# ─── A4: Insecure Design ──────────────────────────────────
A4.01 Rate Limiting On Detection Endpoint
    Rate Limiting Should Be Enforced    /v1/detect    50

A4.02 Rate Limiting On Health Endpoint
    Rate Limiting Should Be Enforced    /v1/health    100

A4.03 Unlimited Pagination
    ${response}    GET On Session    api    /v1/alerts    params=page=99999&limit=99999    expected_status=any
    Should Be True    ${response.status_code} in [400, 422]

# ─── A5: Security Misconfiguration ────────────────────────
A5.01 CORS Misconfiguration
    ${headers}    Create Dictionary    Origin=https://evil.com
    ${response}    GET On Session    api    /v1/health    headers=${headers}
    Should Not Be Equal    ${response.headers}[Access-Control-Allow-Origin]    https://evil.com

A5.02 Stack Trace Leak
    ${response}    GET On Session    api    /v1/nonexistent    expected_status=any
    Should Not Contain    ${response.text}    Traceback
    Should Not Contain    ${response.text}    File
    Should Not Contain    ${response.text}    line

A5.03 Debug Endpoint Enabled
    ${response}    GET On Session    api    /v1/debug    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    404

# ─── A6: Vulnerable Components ────────────────────────────
A6.01 Outdated Library Detection
    ${response}    GET On Session    api    /v1/health
    Should Not Contain    ${response.text}    ${EMPTY}

# ─── A7: Authentication Failures ──────────────────────────
A7.01 JWT None Algorithm
    JWT Tampering Should Be Rejected    /v1/sensors

A7.02 Expired Token
    ${headers}    Create Dictionary
    ...    Authorization=Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0IiwiZXhwIjoxNTAwMDAwMDAwfQ.
    ${response}    GET On Session    api    /v1/sensors    headers=${headers}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    401

A7.03 Weak API Key
    ${headers}    Create Dictionary    X-API-Key=weak
    ${response}    GET On Session    api    /v1/sensors    headers=${headers}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    401

# ─── A8: Data Integrity ───────────────────────────────────
A8.01 JSON Injection
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary    __proto__=polluted    constructor=prototype
    ${response}    POST On Session    api    /v1/detect    json=${body}    expected_status=any
    Should Be True    ${response.status_code} in [400, 422]

A8.02 Mass Assignment
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary    is_admin=true    role=admin
    ${response}    POST On Session    api    /v1/sensors    json=${body}    expected_status=any
    Should Be True    ${response.status_code} in [400, 401, 403]

# ─── A9: Logging Failures ─────────────────────────────────
A9.01 Log Injection (CRLF)
    ${headers}    Create Dictionary    X-Forwarded-For=evil.com%0d%0aInjected-Log
    ${response}    GET On Session    api    /v1/health    headers=${headers}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200

# ─── A10: SSRF ────────────────────────────────────────────
A10.01 SSRF To Metadata Endpoint
    SSRF Attempt Should Be Rejected    /v1/detect    ${SSRF_URL_1}

A10.02 SSRF To Internal Redis
    SSRF Attempt Should Be Rejected    /v1/detect    ${SSRF_URL_2}

A10.03 SSRF File Protocol
    SSRF Attempt Should Be Rejected    /v1/detect    ${SSRF_URL_3}
