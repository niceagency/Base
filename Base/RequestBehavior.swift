//
//  RequestBehavior.swift
//  NABase
//
//  Created by Wain on 31/01/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol RequestBehavior {
    func modify(planned request: URLRequest) -> URLRequest
    func before(sending request: URLRequest)
    
    func after(completion response: URLResponse?)
    func after(failure: Error?, retry: () -> Void)
}

public extension RequestBehavior {
    func modify(planned request: URLRequest) -> URLRequest { return request }
    func before(sending: URLRequest) { }
    
    func after(completion: URLResponse?) { }
    func after(failure: Error?, retry: () -> Void) { }
}

public struct EmptyRequestBehavior: RequestBehavior {
    public init() {}
}

public struct CompositeRequestBehavior: RequestBehavior {
    
    let behaviors: [RequestBehavior]
    
    public init(behaviors: [RequestBehavior]) {
        self.behaviors = behaviors
    }
    
    public func modify(planned r: URLRequest) -> URLRequest {
        var request = r
        
        behaviors.forEach({ request = $0.modify(planned: request) })
        
        return request
    }
    
    public func before(sending request: URLRequest) {
        behaviors.forEach({ $0.before(sending: request) })
    }
    
    public func after(completion response: URLResponse?) {
        behaviors.forEach({ $0.after(completion: response) })
    }
    
    public func after(failure: Error?, retry: () -> Void) {
        behaviors.forEach({ $0.after(failure: failure, retry: retry) })
    }
}
