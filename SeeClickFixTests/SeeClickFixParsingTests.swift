//
//  SeeClickFixParsingTests.swift
//  SeeClickFixTests
//
//  Created by Doug Russell on 12/24/17.
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import XCTest
@testable import SeeClickFix

class SeeClickFixParsingTests: XCTestCase {
    func testParseIssues() {
        guard let url = Bundle(for: SeeClickFixParsingTests.self).url(forResource: "issues", withExtension: "json") else {
            XCTFail()
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            XCTFail()
            return
        }
        guard let issues = try? Issues.decode(data: data) else {
            XCTFail()
            return
        }
        XCTAssertEqual(issues.metadata.pagination.entries, 439829)
        XCTAssertEqual(issues.metadata.pagination.page, 1)
        XCTAssertEqual(issues.metadata.pagination.per_page, 20)
        XCTAssertEqual(issues.metadata.pagination.pages, 21992)
        XCTAssertEqual(issues.metadata.pagination.next_page, 2)
        XCTAssertEqual(issues.metadata.pagination.next_page_url, URL(string: "https://seeclickfix.com/api/v2/issues?address=48219&page=2")!)
        XCTAssertEqual(issues.metadata.pagination.previous_page, nil)
        XCTAssertEqual(issues.metadata.pagination.previous_page_url, nil)
        guard let issue = issues.issues.first else {
            XCTFail()
            return
        }
        XCTAssertEqual(issue.id, .integer(value: 3978183))
        XCTAssertEqual(issue.status, "Open")
        XCTAssertEqual(issue.summary, "Trash / Dumping")
        XCTAssertEqual(issue.description, "Axis/frontage road for Sterling Hill Drive is full of blown trash and leaves. It's clear the monthly landscaping has not touched this location in a while.")
        XCTAssertEqual(issue.rating, 1)
        XCTAssertEqual(issue.lat, 37.9703629214151)
        XCTAssertEqual(issue.lng, -121.760936975098)
        XCTAssertEqual(issue.address, "4852-4898 Sterling Hill Dr Antioch, CA 94531, USA")
        XCTAssertEqual(issue.created_at, ISO8601DateFormatter().date(from: "2017-12-24T11:16:34-05:00"))
        XCTAssertEqual(issue.acknowledged_at, nil)
        XCTAssertEqual(issue.closed_at, nil)
        XCTAssertEqual(issue.reopened_at, nil)
        XCTAssertEqual(issue.updated_at, ISO8601DateFormatter().date(from: "2017-12-24T11:16:52-05:00"))
        XCTAssertEqual(issue.shortened_url, nil)
        XCTAssertEqual(issue.url, URL(string: "https://seeclickfix.com/api/v2/issues/3978183"))
        XCTAssertEqual(issue.html_url, URL(string: "https://seeclickfix.com/issues/3978183"))
    }
}
