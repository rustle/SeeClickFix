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
    enum MockURLSessionError : Error {
        case expectationMissing
        case requestMismatch
    }
    class MockURLSession : SCFURLSession {
        var expectedRequest: URLRequest?
        var expectedResult: SCFURLResult?
        func setURL(_ url: URL) {
            expectedRequest = URLRequest(url: url)
        }
        func scf_dataTaskPromise(with request: URLRequest) -> Promise<SCFURLResult> {
            guard let expectedRequest = expectedRequest,
                  let expectedResult = expectedResult else {
                return Promise(error: MockURLSessionError.expectationMissing)
            }
            guard request == expectedRequest else {
                print(request)
                return Promise(error: MockURLSessionError.requestMismatch)
            }
            let promise = Promise<SCFURLResult>()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 100)) {
                promise.fulfill(expectedResult)
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
        SeeClickFixTests.mockSession.expectedResult = result
        let request = URLRequest(url: url)
        SeeClickFixTests.mockSession.expectedRequest = request
        let expectation = self.expectation(description: #function)
        SeeClickFixTests.mockSession.scf_dataTaskPromise(with: request)
            .then() {
                if result == $0 {
                    expectation.fulfill()
                }
            }
            .catch() {
                print($0)
            }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testLogin() {
        guard let url = URL(string: "https://seeclickfix.com/api/v2/profile") else {
            XCTFail()
            return
        }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            XCTFail()
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Basic dGVzdDp0ZXN0", forHTTPHeaderField: "Authorization")
        SeeClickFixTests.mockSession.expectedRequest = request
        SeeClickFixTests.mockSession.expectedResult = SCFURLResult(data: Data(), response: response)
        let expectation = self.expectation(description: #function)
        SeeClickFixTests.mockNetwork.login(user: "test", password: "test")
            .then() { _ in
                expectation.fulfill()
            }
            .catch() {
                print($0)
            }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testIssues() {
        guard let url = URL(string: "https://seeclickfix.com/api/v2/issues?lat=0.0&lng=0.0&page=0&per_page=100") else {
            XCTFail()
            return
        }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            XCTFail()
            return
        }
        let result = SCFURLResult(data: Data(), response: response)
        SeeClickFixTests.mockSession.setURL(url)
        SeeClickFixTests.mockSession.expectedResult = result
        let location = Point(latitude: 0.0, longitude: 0.0)
        let expectation = self.expectation(description: #function)
        SeeClickFixTests.mockNetwork.issues(location: location, page: 0, count: 100)
            .then() {
                if result.data == $0 {
                    expectation.fulfill()
                }
            }
            .catch() {
                print($0)
            }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testReportTypes() {
        guard let url = URL(string: "https://seeclickfix.com/api/v2/issues/new?lat=0.0&lng=0.0") else {
            XCTFail()
            return
        }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            XCTFail()
            return
        }
        let result = SCFURLResult(data: Data(), response: response)
        SeeClickFixTests.mockSession.setURL(url)
        SeeClickFixTests.mockSession.expectedResult = result
        let location = Point(latitude: 0.0, longitude: 0.0)
        let expectation = self.expectation(description: #function)
        SeeClickFixTests.mockNetwork.reportTypes(location: location)
            .then() { _ in
                expectation.fulfill()
            }
            .catch() {
                print($0)
            }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testReportDetails() {
        guard let url = URL(string: "https://seeclickfix.com/api/v2/request_types/0") else {
            XCTFail()
            return
        }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            XCTFail()
            return
        }
        let result = SCFURLResult(data: Data(), response: response)
        SeeClickFixTests.mockSession.setURL(url)
        SeeClickFixTests.mockSession.expectedResult = result
        let expectation = self.expectation(description: #function)
        SeeClickFixTests.mockNetwork.reportDetails(identifier: 0)
            .then() { _ in
                expectation.fulfill()
            }
            .catch() {
                print($0)
            }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
