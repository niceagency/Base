//
//  TestConstants.swift
//  Base
//
//  Created by Tim Searle on 20/02/2018.
//  Copyright © 2018 Nice Agency. All rights reserved.
//

import Foundation

public struct BaseTestEnvironment {

    public struct SessionConfig {
        public static let key = "TEST_URL_SESSION_CONFIG"
    }
    
    public struct Date {
        public static let key = "TEST_REFERENCE_DATE"
        public static let format = "yyyy-MM-dd'T'HH:mm:ss"
    }
}
