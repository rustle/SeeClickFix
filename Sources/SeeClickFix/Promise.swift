//
//  Promise.swift
//
//  Created by Soroush Khanlou on 7/21/16.
//  Copyright (c) 2016 Soroush Khanlou
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public protocol ExecutionContext {
    func execute(_ work: @escaping () -> Void)
}

extension DispatchQueue : ExecutionContext {
    public func execute(_ work: @escaping () -> Void) {
        self.async(execute: work)
    }
}

public struct DefaultExecutionContext : ExecutionContext {
    public init() {}
    public func execute(_ work: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            work()
        }
    }
}

public enum State<Value>: CustomStringConvertible {
    /// The promise has not completed yet.
    /// Will transition to either the `fulfilled` or `rejected` state.
    case pending

    /// The promise now has a value.
    /// Will not transition to any other state.
    case fulfilled(value: Value)

    /// The promise failed with the included error.
    /// Will not transition to any other state.
    case rejected(error: Error)

    public var isPending: Bool {
        if case .pending = self {
            return true
        } else {
            return false
        }
    }
    
    public var isFulfilled: Bool {
        if case .fulfilled = self {
            return true
        } else {
            return false
        }
    }
    
    public var isRejected: Bool {
        if case .rejected = self {
            return true
        } else {
            return false
        }
    }
    
    public var value: Value? {
        if case let .fulfilled(value) = self {
            return value
        }
        return nil
    }
    
    public var error: Error? {
        if case let .rejected(error) = self {
            return error
        }
        return nil
    }

    public var description: String {
        switch self {
        case .fulfilled(let value):
            return "Fulfilled (\(value))"
        case .rejected(let error):
            return "Rejected (\(error))"
        case .pending:
            return "Pending"
        }
    }
}

public final class Promise<Value> {
    private struct Callback<Value> {
        let onFulfilled: (Value) -> ()
        let onRejected: (Error) -> ()
        let queue: ExecutionContext
        
        func callFulfill(_ value: Value) {
            queue.execute({
                self.onFulfilled(value)
            })
        }
        
        func callReject(_ error: Error) {
            queue.execute({
                self.onRejected(error)
            })
        }
    }

    private var state: State<Value>
    private let lockQueue = DispatchQueue(label: "promise_lock_queue", qos: .userInitiated)
    private var callbacks: [Callback<Value>] = []
    public init() {
        state = .pending
    }
    public init(value: Value) {
        state = .fulfilled(value: value)
    }
    public init(error: Error) {
        state = .rejected(error: error)
    }
    public typealias ErrorYielding = (Error) -> ()
    public typealias FulfillmentYielding<Value> = (Value) -> ()
    public convenience init(queue: ExecutionContext = DefaultExecutionContext(), work: @escaping (@escaping FulfillmentYielding<Value>, @escaping ErrorYielding) throws -> ()) {
        self.init()
        queue.execute {
            do {
                try work(self.fulfill, self.reject)
            } catch let error {
                self.reject(error)
            }
        }
    }

    /// - note: This one is "flatMap"
    @discardableResult
    public func then<NewValue>(on queue: ExecutionContext = DefaultExecutionContext(), _ onFulfilled: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {
        return Promise<NewValue>(queue: queue, work: { fulfill, reject in
            self.addCallbacks(on: queue, onFulfilled: { value in
                do {
                    let promise = try onFulfilled(value)
                    promise.then(fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }, onRejected: reject)
        })
    }
    
    /// - note: This one is "map"
    @discardableResult
    public func then<NewValue>(on queue: ExecutionContext = DefaultExecutionContext(), _ onFulfilled: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {
        return then(on: queue, { value -> Promise<NewValue> in
            do {
                let fulfilledValue = try onFulfilled(value)
                return Promise<NewValue>(value: fulfilledValue)
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        })
    }
    
    @discardableResult
    public func then(on queue: ExecutionContext = DefaultExecutionContext(), _ onFulfilled: @escaping FulfillmentYielding<Value>, _ onRejected: @escaping ErrorYielding = { _ in }) -> Promise<Value> {
        _ = Promise<Value>(work: { fulfill, reject in
            self.addCallbacks(
                on: queue,
                onFulfilled: { value in
                    fulfill(value)
                    onFulfilled(value)
                },
                onRejected: { error in
                    reject(error)
                    onRejected(error)
                }
            )
        })
        return self
    }
    
    @discardableResult
    public func `catch`(on queue: ExecutionContext = DispatchQueue.main, _ onRejected: @escaping (Error) -> ()) -> Promise<Value> {
        return then(on: queue, { _ in }, onRejected)
    }
    
    public func reject(_ error: Error) {
        updateState(.rejected(error: error))
    }
    
    public func fulfill(_ value: Value) {
        updateState(.fulfilled(value: value))
    }
    
    public var isPending: Bool {
        return !isFulfilled && !isRejected
    }
    
    public var isFulfilled: Bool {
        return value != nil
    }
    
    public var isRejected: Bool {
        return error != nil
    }
    
    public var value: Value? {
        return lockQueue.sync(execute: {
            return self.state.value
        })
    }
    
    public var error: Error? {
        return lockQueue.sync(execute: {
            return self.state.error
        })
    }
    
    private func updateState(_ state: State<Value>) {
        guard self.isPending else { return }
        lockQueue.sync(execute: {
            self.state = state
        })
        fireCallbacksIfCompleted()
    }
    
    private func addCallbacks(on queue: ExecutionContext = DispatchQueue.main, onFulfilled: @escaping (Value) -> (), onRejected: @escaping (Error) -> ()) {
        let callback = Callback(onFulfilled: onFulfilled, onRejected: onRejected, queue: queue)
        lockQueue.async(execute: {
            self.callbacks.append(callback)
        })
        fireCallbacksIfCompleted()
    }
    
    private func fireCallbacksIfCompleted() {
        lockQueue.async(execute: {
            guard !self.state.isPending else { return }
            self.callbacks.forEach { callback in
                switch self.state {
                case let .fulfilled(value):
                    callback.callFulfill(value)
                case let .rejected(error):
                    callback.callReject(error)
                default:
                    break
                }
            }
            self.callbacks.removeAll()
        })
    }
}
