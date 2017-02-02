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
    let type: T
    let internalError: Error?
    
    public init(type: T, internalError: Error? = nil) {
        self.type = type
        self.internalError = internalError
    }
    
    var localizedDescription: String {
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
        }
    }
    
    case invalidJSON = 13001
}

public
enum NetworkError: ErrorType {
    
    public var code: Int {
        switch self {
        case .httpError(let status):
            return status
        case .authenticationError:
            return 401
        case .noConnection(let (code,_)):
            return code
        }
    }
    
    public var description: String {
        switch self {
        case .httpError(let status):
            return "Request failed with HTTP status: \(status)"
        case .authenticationError:
            return "Authentication details were rejected"
        case .noConnection(let (_, url)):
            return "No connection available for request to \(url)"
        }
    }
    
    case httpError(Int)
    case authenticationError
    case noConnection(Int,String)
}
