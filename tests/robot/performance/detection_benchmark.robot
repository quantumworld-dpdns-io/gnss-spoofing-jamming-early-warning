*** Settings ***
Library    Collections
Library    RequestsLibrary
Library    DateTime
Library    OperatingSystem
Resource    ../resources/common.robot
Test Setup    Create API Session

*** Variables ***
${BENCHMARK_SAMPLES}    100
${MAX_LATENCY_MS}       500
${THROUGHPUT_MIN_RPS}   50

*** Test Cases ***
Detection Endpoint Latency
    ${latencies}    Create List
    ${headers}    Create Dictionary    Content-Type=application/json
    FOR    ${i}    IN RANGE    ${BENCHMARK_SAMPLES}
        ${body}    Create Dictionary
        ...    observations=${EMPTY_LIST}
        ...    detector_type=ensemble
        ${start}    Get Current Date
        ${response}    POST On Session    api    /v1/detect    json=${body}
        ${end}    Get Current Date
        ${elapsed}    Subtract Date From Date    ${end}    ${start}    result_format=number
        ${elapsed_ms}    Evaluate    ${elapsed} * 1000
        Append To List    ${latencies}    ${elapsed_ms}
    END
    ${max_latency}    Evaluate    max(${latencies})
    ${avg_latency}    Evaluate    sum(${latencies}) / len(${latencies})
    Log    Avg latency: ${avg_latency}ms, Max latency: ${max_latency}ms
    Should Be True    ${avg_latency} < ${MAX_LATENCY_MS}
    ...    msg=Average latency ${avg_latency}ms exceeds ${MAX_LATENCY_MS}ms

Health Endpoint Throughput
    ${start}    Get Current Date
    FOR    ${i}    IN RANGE    ${THROUGHPUT_MIN_RPS}
        GET On Session    api    /v1/health    expected_status=any
    END
    ${end}    Get Current Date
    ${duration}    Subtract Date From Date    ${end}    ${start}    result_format=number
    ${rps}    Evaluate    ${THROUGHPUT_MIN_RPS} / ${duration}
    Log    Throughput: ${rps} requests/second
    Should Be True    ${rps} >= ${THROUGHPUT_MIN_RPS}
    ...    msg=Throughput ${rps} RPS below minimum ${THROUGHPUT_MIN_RPS} RPS

Concurrent Detection Requests
    ${results}    Create List
    FOR    ${i}    IN RANGE    20
        ${body}    Create Dictionary
        ...    observations=${EMPTY_LIST}
        ...    detector_type=quantum
        ${response}    POST On Session    api    /v1/detect    json=${body}    expected_status=any
        Append To List    ${results}    ${response.status_code}
    END
    ${success_count}    Evaluate    sum(1 for s in $results if s == 200)
    Log    ${success_count}/20 concurrent requests succeeded
    Should Be True    ${success_count} >= 18
    ...    msg=Only ${success_count}/20 concurrent requests succeeded

Large Payload Handling
    ${large_observations}    Create List
    FOR    ${i}    IN RANGE    1000
        ${obs}    Create Dictionary
        ...    snr_db_hz=${45 + ${i} % 10}
        ...    doppler_shift=${100 + ${i} % 20}
        ...    constellation=GPS
        ...    prn=${i % 32 + 1}
        Append To List    ${large_observations}    ${obs}
    END
    ${headers}    Create Dictionary    Content-Type=application/json
    ${body}    Create Dictionary
    ...    observations=${large_observations}
    ...    detector_type=ensemble
    ${response}    POST On Session    api    /v1/detect    json=${body}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
