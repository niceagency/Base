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
    
    // Call `begin` at the start of `applicationDidFinishLoading` to initialise test support
    public static func begin() {
        let env = ProcessInfo.processInfo.environment
        
        if let testReferenceDateSetting = env[BaseTestableDate_Environment_key] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX") 
            formatter.dateFormat = BaseTestableDate_Environment_format
            
            TestableDate.testReferenceDate = formatter.date(from: testReferenceDateSetting)
        }
    }
}
