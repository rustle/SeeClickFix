//
//  IssuesJSON.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation

public struct Issues : JSONContainer {
    public let metadata: Metadata
    public struct Metadata : Codable {
        public let pagination: Pagination
        public struct Pagination : Codable {
            public let entries: Int
            public let page: Int
            public let per_page: Int
            public let pages: Int
            public let next_page: Int?
            public let next_page_url: URL?
            public let previous_page: Int?
            public let previous_page_url: URL?
        }
    }
    public let issues: [Issue]
}

public struct Issue : Codable, IdentifierProviding {
    public let id: Strinteger
    public let status: String
    public let summary: String?
    public let description: String?
    public let rating: Int
    public let lat: Double?
    public let lng: Double?
    public let address: String?
    public let created_at: Date
    public let acknowledged_at: Date?
    public let closed_at: Date?
    public let reopened_at: Date?
    public let updated_at: Date?
    public let shortened_url: URL?
    public let html_url: URL
    public let url: URL
    public let reporter: Reporter
    public struct Reporter : Codable {
        public let id: Int?
        public let avatar: Avatar
        public let civic_points: Int?
        public let name: String
        public let role: String
        public let witty_title: String
        public struct Avatar : Codable {
            public let full: URL
            public let square_100x100: URL
        }
    }
    public let media: Media
    public struct Media : Codable {
        public let image_full: URL?
        public let image_square_100x100: URL?
        public let representative_image_url: URL?
        public let video_url: URL?
    }
}
