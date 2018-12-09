//
//  JSONContainer.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation

public protocol JSONContainer : Decodable {
    /// Decode JSON Data
    static func decode(data: Data) throws -> Self
}

public extension JSONContainer {
    public static func decode(data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Self.self, from: data)
    }
}
