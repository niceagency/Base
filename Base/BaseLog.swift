//
//  BaseLog.swift
//  NABase
//
//  Created by Wain on 02/02/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation
import Log

public enum BaseDomain: Int, LogDomain {
    case network = 0
    case coreData = 1
    
    public var description: String {
        switch(self) {
        case .network:
            return "Network"
        case .coreData:
            return "Core Data"
        }
    }
}

public enum BaseLevel: Int, LogLevel {
    case trace = 4
    case debug = 3
    case warn =  2
    case error = 1
    case none =  0
    
    public var description: String {
        switch(self) {
        case .trace:
            return "Trace"
        case .debug:
            return "Debug"
        case .warn:
            return "Warning"
        case .error:
            return "Error"
        case .none:
            return "No specific level"
        }
    }
}

public extension BaseDomain {
    
    private static let networkSpec: Log<BaseDomain, BaseLevel>.LoggerSpec = (domain: .network, level: .none, logger: nil)
    private static let modelSpec: Log<BaseDomain, BaseLevel>.LoggerSpec = (domain: .coreData, level: .none, logger: nil)
    
    static var logStore = Log<BaseDomain, BaseLevel>(specs: [networkSpec, modelSpec])
    
    public func log<T>(_ level: BaseLevel, _ object: T, filename: String = #file, line: Int = #line, funcname: String = #function) {
        let logger = BaseDomain.logStore.log(self)
        
        logger.log(level, object, filename: filename, line: line, funcname: funcname)
    }
}

typealias BaseLog = BaseDomain
