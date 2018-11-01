//
//  Resource.swift
//  NABase
//
//  Created by Wain on 29/09/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol HttpData {
    func encoded() -> Data?
}

public extension HttpData where Self: Encodable {
    func encoded() -> Data? {
        let encoder = JSONEncoder()
        
        return try? encoder.encode(self)
    }
}

extension Data: HttpData {
    public func encoded() -> Data? {
        return self
    }
}

extension Dictionary: HttpData where Key: Encodable, Value: Encodable {
    public func encoded() -> Data? {
        let encoder = JSONEncoder()
        
        return try? encoder.encode(self)
    }
}

extension Array: HttpData where Element: Encodable {
    public func encoded() -> Data? {
        let encoder = JSONEncoder()
        
        return try? encoder.encode(self)
    }
}

public enum HttpMethod {
    case get(HttpData?)
    case post(HttpData?)
    case put(HttpData?)
    case patch(HttpData?)
    case delete(HttpData?)
    
    var name: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        case .patch:
            return "PATCH"
        }
    }
}

public enum CancellationPolicy {
    case none
    case path
    case uri
    case pattern(String)
}

public struct Resource<A: Decodable> {
    public let endpoint: String
    public let method: HttpMethod
    public let query: [URLQueryItem]?
    public let headerProvider: HeaderProvider?
    
    public let errorResponseHandler: ((HTTPErrorData) -> Error?)?
    public let cancellationPolicy: CancellationPolicy
    public let decoder: ResultDecoder
    
    public init(endpoint: String,
                method: HttpMethod = .get(nil),
                query: [URLQueryItem]? = nil,
                headerProvider: HeaderProvider? = nil,
                cancellationPolicy: CancellationPolicy = .none,
                errorResponseHandler: ((HTTPErrorData) -> Error?)? = nil,
                decoder: ResultDecoder = JSONDecoder()) {
        self.endpoint = endpoint
        self.method = method
        self.query = query
        self.cancellationPolicy = cancellationPolicy
        self.headerProvider = headerProvider
        self.errorResponseHandler = errorResponseHandler
        self.decoder = decoder
    }
    
    func parse(_ data: Data, withDecoder: ResultDecoder) -> Result<A> {
        do {
            let parsedObject = try decoder.decode(A.self, from: data)
            return .success(parsedObject)
        } catch let error {
            return .error(error)
        }
    }
}

public protocol ResultDecoder {
    func decode<A>( _ type: A.Type, from: Data) throws -> A where A: Decodable
}

extension JSONDecoder: ResultDecoder {}
