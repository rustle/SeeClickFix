//
//  NetworkController.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation

public protocol Location {
    func queryArguments() throws -> [(String, String)]
}

public struct Point : Location {
    public let latitude: Double
    public let longitude: Double
    public func queryArguments() throws -> [(String, String)] {
        return [("lat", "\(latitude)"), ("lng", "\(longitude)")]
    }
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct BoundingBox : Location {
    /// south west latitude
    public let minLatitude: Double
    /// north east latitude
    public let maxLatitude: Double
    /// southwest longitude
    public let minLongitude: Double
    /// north east longitude
    public let maxLongitude: Double
    public func queryArguments() throws -> [(String, String)] {
        return [
            ("min_lat", "\(minLatitude)"),
            ("min_lng", "\(minLongitude)"),
            ("max_lat", "\(maxLatitude)"),
            ("max_lng", "\(maxLongitude)"),
        ]
    }
}

public struct Address : Location {
    public enum AddressError : Error {
        case encodingError
    }
    public let address: String
    public func queryArguments() throws -> [(String, String)] {
        if let encoded = address.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) {
            return [("address", encoded)]
        }
        throw AddressError.encodingError
    }
    public init(address: String) {
        self.address = address
    }
}

public struct Area : Location {
    public let location: Location
    public let zoom: Double
    public func queryArguments() throws -> [(String, String)] {
        return try location.queryArguments() + [("zoom", "\(zoom)")]
    }
    public init(location: Location, zoom: Double) {
        self.location = location
        self.zoom = zoom
    }
}

public struct SCFURLResult {
    public let data: Data
    public let response: HTTPURLResponse
}

extension SCFURLResult : Equatable {
    public static func ==(lhs: SCFURLResult, rhs: SCFURLResult) -> Bool {
        return lhs.response == rhs.response && lhs.data == rhs.data
    }
}

public protocol SCFURLSession {
    func scf_dataTaskPromise(with request: URLRequest) -> Promise<SCFURLResult>
}

extension URLSession : SCFURLSession {
    public func scf_dataTaskPromise(with request: URLRequest) -> Promise<SCFURLResult> {
        let promise = Promise<SCFURLResult>()
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                promise.reject(error)
            } else if let response = response {
                guard let httpResponse = response as? HTTPURLResponse else {
                    // TODO: Real error
                    promise.reject(NSError())
                    return
                }
                guard let data = data else {
                    // TODO: Real error
                    promise.reject(NSError())
                    return
                }
                promise.fulfill(SCFURLResult(data: data, response: httpResponse))
            } else {
                preconditionFailure()
            }
        }
        task.resume()
        return promise
    }
}

public class NetworkController {
    public static let shared: NetworkController = NetworkController()
    fileprivate struct NetworkOperation {
        public var progress: Progress? {
            get {
                return task.progress
            }
        }
        public func cancel() {
            task.cancel()
        }
        private let task: URLSessionTask
        fileprivate init(task: URLSessionTask) {
            self.task = task
        }
    }
    private enum NetworkError : Error {
        case httpStatus(code: Int)
        case locationWithoutQueryArgument
        case userPasswordDataEncodingFailed
    }
    private struct Constants {
        fileprivate static let httpAuthLoginURL = URL(string: "https://seeclickfix.com/api/v2/profile")!
        fileprivate enum Status : String {
            case open
            case acknowledged
            case closed
            case archived
        }
        fileprivate enum Order : String {
            case updated = "updated_at"
            case created = "created_at"
            case rating
            case distance
        }
        fileprivate enum Direction : String {
            case ascending = "ASC"
            case descending = "DESC"
        }
        static fileprivate let issuesBaseURL = "https://seeclickfix.com/api/v2/issues"
        static fileprivate let reportTypesBaseURL = "https://seeclickfix.com/api/v2/issues/new"
        static fileprivate let reportDetailsBaseURL = URL(string: "https://seeclickfix.com/api/v2/request_types/")!
    }
    private func issuesURL(
        location: Location? = nil,
        page: Int? = nil, // If unspecified, server defaults to 1
        perPage: Int? = nil, // If unspecified, server defaults to 20. Maximum value is 100.
        statuses: [Constants.Status] = [], // If unspecified, server defaults to [.open, .acknowledged, .closed]
        order: Constants.Order? = nil, // If unspecified, server defaults to created
        direction: Constants.Direction? = nil, // If unspecified, server defaults to .descending
        after: Date? = nil, // ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
        before: Date? = nil, // ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
        updatedAtAfter: Date? = nil, // ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
        updateAtBefore: Date? = nil, // ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
        search: String? = nil,
        //request_types=:request_type_id0,:request_type_id1 - comma delimited Request Type ids.
        //assigned_to_me=true - issues assigned to the current_user. NOTE the request must be authenticated or this will be ignored.
        //assigned=:user_id0,:user_id1 - comma delimited user ids,
        //assigned=:user_id0,unassigned - use the string “unassigned” to select unassigned issues
        details: Bool? = nil
    ) throws -> URL {
        var queryArguments = [(String, String)]()
        if let location = location {
            try queryArguments.append(contentsOf: location.queryArguments())
        }
        func append(_ key: String, int: Int?) {
            if let int = int {
                queryArguments.append((key, "\(int)"))
            }
        }
        func append<T>(_ key: String, `enum`: T?) where T : RawRepresentable, T.RawValue == String {
            if let value = `enum`?.rawValue {
                queryArguments.append((key, value))
            }
        }
        func append<T>(_ key: String, enums: [T]) where T : RawRepresentable, T.RawValue == String {
            let joined = enums.map({ value in
                return value.rawValue
            }).joined(separator: ",")
            if joined.count > 0 {
                queryArguments.append((key, joined))
            }
        }
        let formatter = ISO8601DateFormatter()
        func append(_ key: String, date: Date?) {
            if let date = date {
                let iso = formatter.string(from: date)
                queryArguments.append((key, iso))
            }
        }
        append("page", int: page)
        if var perPage = perPage {
            if perPage > 100 {
                perPage = 100
            }
            queryArguments.append(("per_page", "\(perPage)"))
        }
        append("status", enums: statuses)
        append("sort", enum: order)
        append("sort_direction", enum: direction)
        append("after", date: after)
        append("before", date: before)
        if queryArguments.count > 0 {
            let url = Constants.issuesBaseURL + "?" + queryArguments.map({ (key, value) in
                return "\(key)=\(value)"
            }).joined(separator: "&")
            return URL(string: url)!
        }
        return URL(string: Constants.issuesBaseURL)!
    }
    private func reportTypesURL(location: Location) throws -> URL {
        let queryArguments = try location.queryArguments()
        guard queryArguments.count > 0 else {
            throw NetworkError.locationWithoutQueryArgument
        }
        let url = Constants.reportTypesBaseURL + "?" + queryArguments.map({ (key, value) in
            return "\(key)=\(value)"
        }).joined(separator: "&")
        return URL(string: url)!
    }
    private func reportDetailsURL(identifier: Int) -> URL {
        return Constants.reportDetailsBaseURL.appendingPathComponent("\(identifier)")
    }
    private let session: SCFURLSession
    private func unpack(_ result: SCFURLResult) throws -> Promise<Data> {
        switch result.response.statusCode {
        case 200:
            return Promise(value: result.data)
        default:
            throw NetworkError.httpStatus(code: result.response.statusCode)
        }
    }
    public init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
    }
    public init(session: SCFURLSession) {
        self.session = session
    }
    @discardableResult
    public func dataTask(request: URLRequest) -> Promise<SCFURLResult> {
        return session.scf_dataTaskPromise(with: request)
    }
    @discardableResult
    public func login(user: String, password: String) -> Promise<Data> {
        guard let data = "\(user):\(password)".data(using: .utf8) else {
            return Promise(error: NetworkError.userPasswordDataEncodingFailed)
        }
        let request: URLRequest = {
            var request = URLRequest(url: Constants.httpAuthLoginURL)
            let value = "Basic \(data.base64EncodedString())"
            request.setValue(value, forHTTPHeaderField: "Authorization")
            return request
        }()
        return session.scf_dataTaskPromise(with: request).then() {
            return try self.unpack($0)
        }
    }
    @discardableResult
    public func issues(location: Location, page: Int, count: Int) -> Promise<Data> {
        let issuesURL: URL
        do {
            issuesURL = try self.issuesURL(location: location, page: page, perPage: count)
        } catch let error {
            return Promise(error: error)
        }
        let request = URLRequest(url: issuesURL)
        return session.scf_dataTaskPromise(with: request).then {
            return try self.unpack($0)
        }
    }
    @discardableResult
    public func reportTypes(location: Location) -> Promise<Data> {
        let request: URLRequest
        do {
            request = URLRequest(url: try reportTypesURL(location: location))
        } catch let error {
            return Promise(error: error)
        }
        return session.scf_dataTaskPromise(with: request).then {
            return try self.unpack($0)
        }
    }
    @discardableResult
    public func reportDetails(identifier: Int) -> Promise<Data> {
        let request = URLRequest(url: reportDetailsURL(identifier: identifier))
        return session.scf_dataTaskPromise(with: request).then {
            return try self.unpack($0)
        }
    }
}
