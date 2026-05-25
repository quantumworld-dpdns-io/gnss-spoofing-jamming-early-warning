*** Settings ***
Library    RequestsLibrary
Library    String
Library    Collections

*** Keywords ***
SQL Injection Attempt Should Be Rejected
    [Arguments]    ${endpoint}    ${param}    ${payload}
    Create API Session
    ${response}    GET On Session
    ...    api
    ...    ${endpoint}
    ...    params=${param}=${payload}
    ...    expected_status=any
    Should Be True
    ...    ${response.status_code} in [400, 401, 403, 422, 500]
    ...    msg=SQL injection on ${endpoint} was not rejected

XSS Attempt Should Be Sanitized
    [Arguments]    ${endpoint}    ${payload}
    Create API Session
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary    input=${payload}
    ${response}    POST On Session
    ...    api
    ...    ${endpoint}
    ...    json=${body}
    ...    expected_status=any
    Should Not Contain    ${response.text}    <script>alert
    ...    msg=XSS payload was reflected unsanitized

JWT Tampering Should Be Rejected
    [Arguments]    ${endpoint}
    Create API Session
    ${headers}    Create Dictionary
    ...    Authorization=Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJhZG1pbiIsInJvbGUiOiJhZG1pbiJ9.
    ${response}    GET On Session
    ...    api
    ...    ${endpoint}
    ...    headers=${headers}
    ...    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    401
    ...    msg=Tampered JWT was accepted

Path Traversal Should Be Rejected
    [Arguments]    ${endpoint}    ${payload}
    Create API Session
    ${response}    GET On Session
    ...    api
    ...    ${endpoint}
    ...    params=file=${payload}
    ...    expected_status=any
    Should Be True
    ...    ${response.status_code} in [400, 403, 404]
    ...    msg=Path traversal on ${endpoint} was not rejected

NoSQL Injection Should Be Rejected
    [Arguments]    ${endpoint}
    Create API Session
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    query={"$ne": null}
    ...    username={"$gt": ""}
    ${response}    POST On Session
    ...    api
    ...    ${endpoint}
    ...    json=${body}
    ...    expected_status=any
    Should Be True
    ...    ${response.status_code} in [400, 401, 403, 500]
    ...    msg=NoSQL injection was not rejected

Rate Limiting Should Be Enforced
    [Arguments]    ${endpoint}    ${max_requests}=100
    Create API Session
    ${status_codes}    Create List
    FOR    ${i}    IN RANGE    ${max_requests + 10}
        ${response}    GET On Session
        ...    api
        ...    ${endpoint}
        ...    expected_status=any
        Append To List    ${status_codes}    ${response.status_code}
    END
    ${rate_limited}    Evaluate    429 in $status_codes
    Should Be True    ${rate_limited}    msg=Rate limiting was not enforced

Command Injection Should Be Rejected
    [Arguments]    ${endpoint}    ${payload}
    Create API Session
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary    command=${payload}
    ${response}    POST On Session
    ...    api
    ...    ${endpoint}
    ...    json=${body}
    ...    expected_status=any
    Should Be True
    ...    ${response.status_code} in [400, 403, 500]
    ...    msg=Command injection was not rejected

Missing Auth Should Return 401
    [Arguments]    ${endpoint}    ${method}=GET
    Create API Session
    ${response}    ${method} On Session
    ...    api
    ...    ${endpoint}
    ...    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    401
    ...    msg=Missing auth on ${endpoint} did not return 401

SSRF Attempt Should Be Rejected
    [Arguments]    ${endpoint}    ${url_payload}
    Create API Session
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary    url=${url_payload}
    ${response}    POST On Session
    ...    api
    ...    ${endpoint}
    ...    json=${body}
    ...    expected_status=any
    Should Be True
    ...    ${response.status_code} in [400, 403, 500]
    ...    msg=SSRF attempt was not rejected
