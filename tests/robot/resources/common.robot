*** Settings ***
Library    Collections
Library    String
Library    RequestsLibrary
Library    OperatingSystem
Library    Process
Library    DateTime

*** Variables ***
${API_BASE_URL}    http://localhost:8080
${MCP_URL}         http://localhost:8090
${BROWSER}         chromium
${TIMEOUT}         30s
${ADMIN_TOKEN}     test-admin-token
${USER_TOKEN}      test-user-token
${API_KEY}         test-api-key-12345

*** Keywords ***
Create API Session
    [Arguments]    ${alias}=api    ${url}=${API_BASE_URL}
    Create Session    ${alias}    ${url}    timeout=${TIMEOUT}

Create MCP Session
    [Arguments]    ${alias}=mcp    ${url}=${MCP_URL}
    Create Session    ${alias}    ${url}    timeout=${TIMEOUT}

Health Check Should Succeed
    Create API Session
    ${response}    GET On Session    api    /v1/health
    Should Be Equal As Integers    ${response.status_code}    200
    Dictionary Should Contain Key    ${response.json()}    status
    Should Be Equal    ${response.json()}[status]    ok

Generate Random String
    [Arguments]    ${length}=8
    ${result}    Generate Random String    ${length}    [LETTERS][NUMBERS]
    [Return]    ${result}

Load Test Data
    [Arguments]    ${filename}
    ${data}    Get File    ${CURDIR}/../data/${filename}
    [Return]    ${data}

Assert Detection Result
    [Arguments]    ${response}    ${expected_status}=200
    Should Be Equal As Integers    ${response.status_code}    ${expected_status}
    ${json}    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${json}    is_spoofed
    [Return]    ${json}
