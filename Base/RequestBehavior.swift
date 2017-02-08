//
//  RequestBehavior.swift
//  NABase
//
//  Created by Wain on 31/01/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol RequestBehavior {
    
    var additionalHeaders: [(String, String)] { get }
    
    func beforeSend()
    
    func afterComplete()
    func afterFailure(error: Error?)
}

public extension RequestBehavior {
    var additionalHeaders: [(String, String)] {
        return []
    }
    
    func beforeSend() { }
    
    func afterComplete() { }
    func afterFailure(error: Error?) { }
}

public struct EmptyRequestBehavior: RequestBehavior {
    public init() {}
}

public struct CompositeRequestBehavior: RequestBehavior {
    
    let behaviors: [RequestBehavior]
    
    public init(behaviors: [RequestBehavior]) {
        self.behaviors = behaviors
    }
    
    public var additionalHeaders: [(String, String)] {
        return behaviors.reduce([(String, String)](), { sum, behavior in
            return sum + behavior.additionalHeaders
        })
    }
    
    public func beforeSend() {
        behaviors.forEach({ $0.beforeSend() })
    }
    
    public func afterComplete() {
        behaviors.forEach({ $0.afterComplete() })
    }
    
    public func afterFailure(error: Error?) {
        behaviors.forEach({ $0.afterFailure(error: error) })
    }
}
