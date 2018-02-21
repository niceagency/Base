//
//  TestSystem.swift
//  Base
//
//  Created by Wain on 29/11/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation
import Log

// Container for logic applying to the test support infrastructure
public struct TestSystem {
    
    public static var testURLSession: URLSession? 
    
    // Call `begin` at the start of `applicationDidFinishLoading` to initialise test support
    public static func begin() {
        
        var testing = false
        
        let env = ProcessInfo.processInfo.environment
        
        if let testURLStubSetting = env[BaseTestEnvironment.SessionConfig.key] {
            let config = TestURLSessionConfiguration(environmentVariable: testURLStubSetting)
            testURLSession = TestURLSession(testMapping: config)
            testing = true
        }
        
        if let testReferenceDateSetting = env[BaseTestEnvironment.Date.key] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX") 
            formatter.dateFormat = BaseTestEnvironment.Date.format
            
            TestableDate.testReferenceDate = formatter.date(from: testReferenceDateSetting)
            testing = true
        }
        
        if testing {
            BaseDomain.logStore = Log<BaseDomain, BaseLevel>(specs: [
                (domain: .network, level: .none, logger: nil),
                (domain: .coreData, level: .none, logger: nil),
                (domain: .testSupport, level: .trace, logger: nil)
                ])
        }
    }
    
    public static func environmentRepresentation(forTestReferenceDate date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") 
        formatter.dateFormat = BaseTestEnvironment.Date.format
        
        return formatter.string(from: date)
    }
}
