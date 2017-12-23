//
//  Strinteger.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation

public enum Strinteger : Codable {
    case integer(value: Int)
    case string(value: String)
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        do {
            let value = try value.decode(Int.self)
            self = .integer(value: value)
        } catch {
            let value = try value.decode(String.self)
            self = .string(value: value)
        }
    }
    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .integer(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let .string(value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
    public enum StrintegerError : Error {
        case conversionError
    }
    func convert() throws -> Int {
        switch self {
        case let .integer(value):
            return value
        case let .string(string):
            let formatter = NumberFormatter()
            let number = formatter.number(from: string)
            if let value = number?.intValue {
                return value
            }
        }
        throw StrintegerError.conversionError
    }
}
