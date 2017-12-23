//
//  SeeClickFixTests.swift
//  SeeClickFixTests
//
//  Created by Doug Russell on 12/22/17.
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import XCTest
@testable import SeeClickFix

class SeeClickFixTests: XCTestCase {
    class MockURLSession : SCFURLSession {
        var nextResult: SCFURLResult?
        func scf_dataTaskPromise(with request: URLRequest) -> Promise<SCFURLResult> {
            let promise = Promise<SCFURLResult>()
            if let result = nextResult {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 100)) {
                    promise.fulfill(result)
                }
            } else {
                preconditionFailure()
            }
            return promise
        }
    }
    static let mockSession = MockURLSession()
    static let mockNetwork = NetworkController(session: SeeClickFixTests.mockSession)
    func testMockSession() {
        guard let url = URL(string: "http://example.com") else {
            XCTFail()
            return
        }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            XCTFail()
            return
        }
        let result = SCFURLResult(data: Data(), response: response)
        SeeClickFixTests.mockSession.nextResult = result
        let urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 1.0)
        let expectation = self.expectation(description: "testMockSession")
        SeeClickFixTests.mockSession.scf_dataTaskPromise(with: urlRequest).then() { 
            if result == $0 {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
