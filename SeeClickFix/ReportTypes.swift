//
//  ReportTypes.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation

public struct ReportTypes : JSONContainer {
    public let request_types: [ReportType]
}

public struct ReportType : Codable, IdentifierProviding {
    public let title: String
    public let id: Strinteger
    public let private_visibility: Bool?
    public let organization: String?
    public let url: URL?
    public let potential_duplicate_issues_url: URL?
}
