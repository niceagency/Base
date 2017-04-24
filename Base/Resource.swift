//
//  Resource.swift
//  NABase
//
//  Created by Wain on 29/09/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public enum HttpMethod<Body> {
    case get(Body?)
    case post(Body?)
    case put(Body?)
    case delete(Body?)
}

public enum CancellationPolicy {
    case none
    case path
    case uri
    case pattern(String)
}

public enum ParseResult<T> {
    case success(T)
    case error(Error)
}

public struct Resource<A> {
    public let endpoint: String
    public let method: HttpMethod<Any>
    public let query: [URLQueryItem]?
    public let headerProvider: HeaderProvider?
    public let parse: (Data) -> (ParseResult<A>)
    public let errorResponseHandler: ((Int, Data?) -> (Error?))?
    public let cancellationPolicy: CancellationPolicy
    
    public init(endpoint: String,
         method: HttpMethod<Any> = .get(nil),
         query: [URLQueryItem]? = nil,
         headerProvider: HeaderProvider? = nil,
         cancellationPolicy: CancellationPolicy = .none,
         errorResponseHandler: ((Int, Data?) -> (Error?))? = nil,
         parse: @escaping (Data) -> (ParseResult<A>)) {
        
        self.endpoint = endpoint
        self.method = method
        self.query = query
        self.cancellationPolicy = cancellationPolicy
        self.headerProvider = headerProvider
        self.errorResponseHandler = errorResponseHandler
        self.parse = parse
    }
}
