//
//  Network.swift
//  NABase
//
//  Created by Tim Searle on 16/11/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation
import Reachability

public struct Network {
    
    public struct ReachabilityTester {
        public static let shared: Reachability? = {
            let reachability = Reachability(hostname: "google.com")
            
            if let tester = reachability {
                tester.whenReachable = { _ in
                    DispatchQueue.main.async {
                        BaseLog.network.log(.trace, "Network is reachable")
                        Network.ReachabilityTester.isReachable = true
                    }
                }
                tester.whenUnreachable = { _ in
                    DispatchQueue.main.async {
                        BaseLog.network.log(.trace, "Network is NOT reachable")
                        Network.ReachabilityTester.isReachable = false
                    }
                }
                
                do {
                    try tester.startNotifier()
                } catch {
                    BaseLog.network.log(.error, "Unable to start reachability notifier: \(error)")
                }
            } else {
                Network.ReachabilityTester.isReachable = true
            }
            
            return reachability
        }()
        public static private(set) var isReachable = false
        
        public static func beginSharedReachabilityMonitoring() {
            let _ = shared
        }
    }
    
    public struct Webservices {
        private static var webservices: [String : Webservice] = [:]
        
        public static func add(baseURLs: [String]) {
            for baseURL in baseURLs {
                webservices[baseURL] = Webservice(baseURL: URL(string: baseURL)!)
            }
        }
        
        public static func add(baseURL: String, authorizationHandler: UnauthorizedResponseHandler) {
            webservices[baseURL] = Webservice(baseURL: URL(string: baseURL)!, unauthorizedResponseHandler: authorizationHandler)
        }
        
        public static func baseURL(_ baseURL: String) -> Webservice {
            return webservices[baseURL]!
        }
    }
}
