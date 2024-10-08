// Copyright (c) 2022 WSO2 LLC (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import choreo/mediation;
import ballerina/log;
import ballerina/http;

const HEADER_X_REQUEST_ID = "x-request-id";
const FIELD_NAME_PAYLOAD = "payload";
const FIELD_NAME_HEADERS = "headers";
const ERR_MSG_MISSING_REQ_ID = "<request-id-unavailable>";

@mediation:RequestFlow
public function logRequestMessage(mediation:Context ctx, http:Request req, boolean Log\ Payload = false, boolean Log\ Headers = false,
                                    string Excluded\ Headers = "") returns http:Response|false|error|() {
    LogRecord lRec = {
        mediation\-flow: REQUEST,
        request\-id: "",
        http\-method: req.method,
        resource\-path: ctx.originalContext().resourcePath().toString()
    };

    if req.hasHeader(HEADER_X_REQUEST_ID) {
        lRec.request\-id = checkpanic req.getHeader(HEADER_X_REQUEST_ID);
    } else {
        lRec.request\-id = ERR_MSG_MISSING_REQ_ID;
    }

    if Log\ Payload {
        string|http:ClientError payload = req.getTextPayload();

        if payload is http:ClientError {
            log:printWarn("Error while reading request payload", payload);
        } else {
            lRec[FIELD_NAME_PAYLOAD] = payload;
        }
    }

    if Log\ Headers {
        lRec[FIELD_NAME_HEADERS] = buildRequestHeadersMap(req, Excluded\ Headers);
    }

    log:printInfo("", (), (), lRec);
    return ();
}

@mediation:ResponseFlow
public function logResponseMessage(mediation:Context ctx, http:Request req, http:Response res, boolean Log\ Payload = false,
                                    boolean Log\ Headers = false, string Excluded\ Headers = "")
                                                                returns http:Response|false|error|() {
    LogRecord lRec = {
        mediation\-flow: RESPONSE,
        request\-id: "",
        http\-method: req.method,
        resource\-path: ctx.originalContext().resourcePath().toString()
    };

    if res.hasHeader(HEADER_X_REQUEST_ID) {
        lRec.request\-id = checkpanic res.getHeader(HEADER_X_REQUEST_ID);
    } else {
        lRec.request\-id = ERR_MSG_MISSING_REQ_ID;
    }

    if Log\ Payload {
        string|http:ClientError payload = res.getTextPayload();

        if payload is http:ClientError {
            log:printWarn("Error while reading response payload", payload);
        } else {
            lRec[FIELD_NAME_PAYLOAD] = payload;
        }
    }

    if Log\ Headers {
        lRec[FIELD_NAME_HEADERS] = buildResponseHeadersMap(res, Excluded\ Headers);
    }

    log:printInfo("", (), (), lRec);
    return ();
}

@mediation:FaultFlow
public function logFaultMessage(mediation:Context ctx, http:Request req, http:Response? resp,
                                    http:Response errFlowResp, error e, boolean Log\ Payload = false, boolean Log\ Headers = false,
                                        string Excluded\ Headers = "")
                                                                returns http:Response|false|error|() {
    LogRecord lRec = {
        mediation\-flow: FAULT,
        request\-id: "",
        http\-method: req.method,
        resource\-path: ctx.originalContext().resourcePath().toString()
    };

    // Since the fault flow may be triggered by both the request flow and the response flow, we take the x-request-id
    // header from the flow which triggered the fault flow (if the request flow triggered it, response will be nil)
    if resp is () {
        if req.hasHeader(HEADER_X_REQUEST_ID) {
            lRec.request\-id = checkpanic req.getHeader(HEADER_X_REQUEST_ID);
        } else {
            lRec.request\-id = ERR_MSG_MISSING_REQ_ID;
        }
    } else {
        if resp.hasHeader(HEADER_X_REQUEST_ID) {
            lRec.request\-id = checkpanic resp.getHeader(HEADER_X_REQUEST_ID);
        } else {
            lRec.request\-id = ERR_MSG_MISSING_REQ_ID;
        }
    }

    if Log\ Payload {
        string|http:ClientError payload = errFlowResp.getTextPayload();

        if payload is http:ClientError {
            log:printWarn("Error while reading fault payload", payload);
        } else {
             lRec[FIELD_NAME_PAYLOAD] = payload;
        }
    }

    if Log\ Headers {
        if resp is () {
            // In case response is nil, request hasn't reached the backend, hence logging the request headers.
            lRec[FIELD_NAME_HEADERS] = buildRequestHeadersMap(req, Excluded\ Headers);
        } else {
            lRec[FIELD_NAME_HEADERS] = buildResponseHeadersMap(resp, Excluded\ Headers);
        }
    }

    log:printInfo("", (), (), lRec);
    return ();
}
