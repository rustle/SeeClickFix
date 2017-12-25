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
        XCTAssertEqual(issue.comment_url, URL(string: "https://seeclickfix.com/api/v2/issues/3978183/comments"))
        XCTAssertEqual(issue.flag_url, URL(string: "https://seeclickfix.com/api/v2/issues/3978183/flag"))
        XCTAssertEqual(issue.request_type.id, 18605)
        XCTAssertEqual(issue.request_type.title, "Trash / Dumping")
        XCTAssertEqual(issue.request_type.organization, "City of Antioch")
        XCTAssertEqual(issue.request_type.url, URL(string: "https://seeclickfix.com/api/v2/request_types/18605"))
        XCTAssertEqual(issue.request_type.related_issues_url, URL(string: "https://seeclickfix.com/api/v2/issues?lat=37.9703629214151&lng=-121.760936975098&request_types=18605&sort=distance"))
        XCTAssertEqual(issue.transitions.close_url, URL(string: "https://seeclickfix.com/api/v2/issues/3978183/close"))
        XCTAssertEqual(issue.reporter.id, 1440862)
        XCTAssertEqual(issue.reporter.name, "Mike G.")
        XCTAssertEqual(issue.reporter.witty_title, "City Fixer")
        XCTAssertEqual(issue.reporter.role, "Registered User")
        XCTAssertEqual(issue.reporter.civic_points, 3250)
        XCTAssertEqual(issue.reporter.avatar.full, URL(string: "https://seeclickfix.com/assets/no-avatar-100-5e06fcc664c6376bbf654cbd67df857ff81918c5f5c6a2345226093147382de9.png"))
        XCTAssertEqual(issue.reporter.avatar.square_100x100, URL(string: "https://seeclickfix.com/assets/no-avatar-100-5e06fcc664c6376bbf654cbd67df857ff81918c5f5c6a2345226093147382de9.png"))
        XCTAssertEqual(issue.media.video_url, nil)
        XCTAssertEqual(issue.media.image_full, URL(string: "https://seeclickfix.com/files/issue_images/0093/5793/1514132184511.jpg"))
        XCTAssertEqual(issue.media.image_square_100x100, URL(string: "https://seeclickfix.com/files/issue_images/0093/5793/1514132184511_square.jpg"))
        XCTAssertEqual(issue.media.representative_image_url, URL(string: "https://seeclickfix.com/files/issue_images/0093/5793/1514132184511_square.jpg"))
    }
}
