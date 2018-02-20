//
//  NetworkTransformers.swift
//  Base
//
//  Created by Tim Searle on 19/02/2018.
//  Copyright © 2018 Nice Agency. All rights reserved.
//

import Foundation

extension URLComponents {
    func transformer() -> URLComponentsTransformer {
        return URLComponentsTransformer(self)
    }
}

extension URLRequest {
    func transformer() -> URLRequestTransformer {
        return URLRequestTransformer(self)
    }
}

enum URLComponentsTransformerError: Error {
    case badComponents
}

final class URLComponentsTransformer {
    private var storedURLComponents: URLComponents
    
    init(_ urlComponents: URLComponents) {
        self.storedURLComponents = urlComponents
    }
    
    func request() throws -> URLRequest {
        guard let url = storedURLComponents.url else {
            throw URLComponentsTransformerError.badComponents
        }
        
        return URLRequest(url: url)
    }
    
    func requestTransformer() throws -> URLRequestTransformer {
        guard let requestTransformer = try? requestTransformer() else {
            throw URLComponentsTransformerError.badComponents
        }
        
        return requestTransformer
    }
    
    func components() -> URLComponents {
        return storedURLComponents
    }
    
    func replacing(queryItems: [URLQueryItem]?) -> URLComponentsTransformer {
        storedURLComponents.queryItems = queryItems
        return self
    }
    
    func appending(queryItems: [URLQueryItem]) -> URLComponentsTransformer {
        let existingQueryItems = storedURLComponents.queryItems ?? []
        storedURLComponents.queryItems = existingQueryItems + queryItems
        return self
    }
    
    func modifying(scheme: String?) -> URLComponentsTransformer {
        storedURLComponents.scheme = scheme
        return self
    }
    
    func modifying(port: Int?) -> URLComponentsTransformer {
        storedURLComponents.port = port
        return self
    }
    
    func modifying(path: String) -> URLComponentsTransformer {
        storedURLComponents.path = path
        return self
    }
    
    func modifying(host: String?) -> URLComponentsTransformer {
        storedURLComponents.host = host
        return self
    }
}

final class URLRequestTransformer {
    private var storedRequest: URLRequest
    
    init(_ request: URLRequest) {
        self.storedRequest = request
    }
    
    func request() -> URLRequest {
        return storedRequest
    }
    
    func appending(headers: [(String, String)]) -> URLRequestTransformer {
        
        var request = storedRequest
        
        headers.forEach { header, value in
            request.addValue(value, forHTTPHeaderField: header)
        }
        
        storedRequest = request
        
        return self
    }
    
    func modifying(cachePolicy: NSURLRequest.CachePolicy) -> URLRequestTransformer {
        var request = storedRequest
        request.cachePolicy = cachePolicy
        
        storedRequest = request
        
        return self
    }
}
