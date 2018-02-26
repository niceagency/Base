//
//  NetworkTransformers.swift
//  Base
//
//  Created by Tim Searle on 19/02/2018.
//  Copyright © 2018 Nice Agency. All rights reserved.
//

import Foundation

public extension URLRequest {
    public func appending(headers: [(String, String)]) -> URLRequest {
        
        var copy = self
        headers.forEach { header, value in
            copy.addValue(value, forHTTPHeaderField: header)
        }

        return copy
    }
    
    public func modifying(cachePolicy: NSURLRequest.CachePolicy) -> URLRequest {
        var copy = self
        copy.cachePolicy = cachePolicy
        return copy
    }
}

public extension URLComponents {
    public func replacing(queryItems: [URLQueryItem]?) -> URLComponents {
        var copy = self
        copy.queryItems = queryItems
        return copy
    }
    
    public func appending(queryItems: [URLQueryItem]) -> URLComponents {
        var copy = self
        let existingQueryItems = self.queryItems ?? []
        copy.queryItems = existingQueryItems + queryItems
        return copy
    }
    
    public func modifying(scheme: String?) -> URLComponents {
        var copy = self
        copy.scheme = scheme
        return copy
    }
    
    public func modifying(port: Int?) -> URLComponents {
        var copy = self
        copy.port = port
        return copy
    }
    
    public func modifying(path: String) -> URLComponents {
        var copy = self
        copy.path = path
        return copy
    }
    
    public func modifying(host: String?) -> URLComponents {
        var copy = self
        copy.host = host
        return copy
    }
}
