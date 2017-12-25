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

extension Strinteger : Equatable {
    public static func ==(lhs: Strinteger, rhs: Strinteger) -> Bool {
        switch lhs {
        case let .integer(leftValue):
            switch rhs {
            case let .integer(rightValue):
                return leftValue == rightValue
            case .string:
                do {
                    let convertedValue = try rhs.convert()
                    return leftValue == convertedValue
                } catch {
                    return false
                }
            }
        case let .string(leftValue):
            switch rhs {
            case let .integer(rightValue):
                do {
                    let convertedValue = try lhs.convert()
                    return rightValue == convertedValue
                } catch {
                    return false
                }
            case let .string(rightValue):
                return leftValue == rightValue
            }
        }
    }
}
