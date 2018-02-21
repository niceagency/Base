//
//  NetworkTransformers.swift
//  Base
//
//  Created by Tim Searle on 19/02/2018.
//  Copyright © 2018 Nice Agency. All rights reserved.
//

import Foundation

public extension URLComponents {
    func transformer() -> URLComponentsTransformer {
        return URLComponentsTransformer(self)
    }
}

public extension URLRequest {
    func transformer() -> URLRequestTransformer {
        return URLRequestTransformer(self)
    }
}

public final class URLComponentsTransformer {
    private var storedURLComponents: URLComponents
    
    public init(_ urlComponents: URLComponents) {
        self.storedURLComponents = urlComponents
    }
    
    public func request() throws -> URLRequest {
        guard let url = storedURLComponents.url else {
            throw NAError<URLComponentsTransformerError>(type: .badComponents)
        }
        
        return URLRequest(url: url)
    }
    
    public func requestTransformer() throws -> URLRequestTransformer {
        guard let request = try? request() else {
            throw NAError<URLComponentsTransformerError>(type: .badComponents)
        }
        
        return request.transformer()
    }
    
    public func components() -> URLComponents {
        return storedURLComponents
    }
    
    public func replacing(queryItems: [URLQueryItem]?) -> URLComponentsTransformer {
        storedURLComponents.queryItems = queryItems
        return self
    }
    
    public func appending(queryItems: [URLQueryItem]) -> URLComponentsTransformer {
        let existingQueryItems = storedURLComponents.queryItems ?? []
        storedURLComponents.queryItems = existingQueryItems + queryItems
        return self
    }
    
    public func modifying(scheme: String?) -> URLComponentsTransformer {
        storedURLComponents.scheme = scheme
        return self
    }
    
    public func modifying(port: Int?) -> URLComponentsTransformer {
        storedURLComponents.port = port
        return self
    }
    
    public func modifying(path: String) -> URLComponentsTransformer {
        storedURLComponents.path = path
        return self
    }
    
    public func modifying(host: String?) -> URLComponentsTransformer {
        storedURLComponents.host = host
        return self
    }
}

public final class URLRequestTransformer {
    private var storedRequest: URLRequest
    
    public init(_ request: URLRequest) {
        self.storedRequest = request
    }
    
    public func request() -> URLRequest {
        return storedRequest
    }
    
    public func appending(headers: [(String, String)]) -> URLRequestTransformer {
        
        var request = storedRequest
        
        headers.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header)
        }
        
        storedRequest = request
        
        return self
    }
    
    public func modifying(cachePolicy: NSURLRequest.CachePolicy) -> URLRequestTransformer {
        var request = storedRequest
        request.cachePolicy = cachePolicy
        
        storedRequest = request
        
        return self
    }
}
