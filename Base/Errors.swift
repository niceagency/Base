//
//  Errors.swift
//  NABase
//
//  Created by Tim Searle on 19/10/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol ErrorType {
    var domain: String { get }
    var description: String { get }
    var code: Int { get }
}

public extension ErrorType {
    var domain: String {
        return String(describing: type(of: self))
    }
}

public struct NAError<T: ErrorType>: Error {
    public let type: T
    public let internalError: Error?
    
    public init(type: T, internalError: Error? = nil) {
        self.type = type
        self.internalError = internalError
    }
    
    public var localizedDescription: String {
        return "\(type.domain) - \(type.description) (\(type.code))"
    }
}

public enum DataError: Int, ErrorType {
    
    public var code: Int {
        return self.rawValue
    }
    
    public var description: String {
        switch self {
        case .invalidJSON:
            return NSLocalizedString("error.data.invalid json", comment: "")
        case .parse:
            return NSLocalizedString("error.data.parse.failure", comment: "")
        }
    }
    
    case invalidJSON = 13001
    case parse = 13002
}

public enum NetworkError: ErrorType {
    
    public var code: Int {
        switch self {
        case let .httpError(status):
            return status
        case .authenticationError:
            return 401
        case let.noConnection(code, _):
            return code
        case .malformedURL:
            return 13003
        }
    }
    
    public var description: String {
        switch self {
        case let .httpError(status):
            return "Request failed with HTTP status: \(status)"
        case .authenticationError:
            return "Authentication details were rejected"
        case let .noConnection(_, url):
            return "No connection available for request to \(url)"
        case .malformedURL:
            return "URL in request is malformed"
        }
    }
    
    case httpError(Int)
    case authenticationError
    case noConnection(Int, String)
    case malformedURL
}

public enum URLComponentsTransformerError: ErrorType {
    case badComponents
    
    public var description: String {
        switch self {
        case .badComponents:
            return "Components provided cannot form a valid URL"
        }
    }
    
    public var code: Int {
        switch self {
        case .badComponents:
            return 13004
        }
    }
}

public struct HTTPErrorData {
    
    public let responseCode: Int
    public let data: Data?
    
    init?(responseCode: Int, data: Data? ) {
        
        let validRange: ClosedRange = 400...599
        
        guard validRange.contains(responseCode) else {
            return nil
        }
        
        self.responseCode = responseCode
        self.data = data
    }
}
