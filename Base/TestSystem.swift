//
//  TestSystem.swift
//  Base
//
//  Created by Wain on 29/11/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

// Container for logic applying to the test support infrastructure
public struct TestSystem {
    
    public static var testURLSession: URLSession? 
    
    // Call `begin` at the start of `applicationDidFinishLoading` to initialise test support
    public static func begin() {
        let env = ProcessInfo.processInfo.environment
        
        if let testURLStubSetting = env[BaseTestableSession_Config_Environment_key] {
            let config = TestURLSessionConfiguration(environmentVariable: testURLStubSetting)
            testURLSession = TestURLSession(testMapping: config)
        }
        
        if let testReferenceDateSetting = env[BaseTestableDate_Environment_key] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX") 
            formatter.dateFormat = BaseTestableDate_Environment_format
            
            TestableDate.testReferenceDate = formatter.date(from: testReferenceDateSetting)
        }
    }
    
    public static func environmentRepresentation(forTestReferenceDate date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") 
        formatter.dateFormat = BaseTestableDate_Environment_format
        
        return formatter.string(from: date)
    }
}
