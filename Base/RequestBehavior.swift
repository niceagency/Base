//
//  RequestBehavior.swift
//  NABase
//
//  Created by Wain on 31/01/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol RequestBehavior {
    func modify(request: URLRequest) -> URLRequest
    func beforeSend(ofRequest: URLRequest)
    
    func afterComplete(withResponse: URLResponse?)
    func afterFailure(error: Error?, retry: () -> Void)
}

public extension RequestBehavior {
    func modify(request: URLRequest) -> URLRequest { return request }
    func beforeSend(ofRequest: URLRequest) { }
    
    func afterComplete(withResponse: URLResponse?) { }
    func afterFailure(error: Error?, retry: () -> Void) { }
}

public struct EmptyRequestBehavior: RequestBehavior {
    public init() {}
}

public struct CompositeRequestBehavior: RequestBehavior {
    
    let behaviors: [RequestBehavior]
    
    public init(behaviors: [RequestBehavior]) {
        self.behaviors = behaviors
    }
    
    public func modify(request r: URLRequest) -> URLRequest {
        var request = r
        
        behaviors.forEach({ request = $0.modify(request: request) })
        
        return request
    }
    
    public func beforeSend(ofRequest request: URLRequest) {
        behaviors.forEach({ $0.beforeSend(ofRequest: request) })
    }
    
    public func afterComplete(withResponse response: URLResponse?) {
        behaviors.forEach({ $0.afterComplete(withResponse: response) })
    }
    
    public func afterFailure(error: Error?, retry: () -> Void) {
        behaviors.forEach({ $0.afterFailure(error: error, retry: retry) })
    }
}
