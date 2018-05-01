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
                
                Network.ReachabilityTester.isReachable = tester.connection != .none
            } else {
                Network.ReachabilityTester.isReachable = true
            }
            
            return reachability
        }()
        public static private(set) var isReachable = false
        
        public static func beginSharedReachabilityMonitoring() {
            _ = shared
        }
    }
    
    public struct Webservices {
        private static var webservices: [String: Webservice] = [:]
        
        @discardableResult public static func add(baseURLs: [String]) -> [Webservice] {
            var services: [Webservice] = []
            
            for baseURL in baseURLs {
                let webservice = Webservice(baseURL: URL(string: baseURL)!)
                
                webservices[baseURL] = webservice
                services.append(webservice)
            }
            
            return services
        }
        
        @discardableResult public static func add(baseURL: String,
                                                  authorizationHandler: UnauthorizedResponseHandler? = nil,
                                                  defaultHeaders: HeaderProvider? = nil,
                                                  session: URLSession = URLSession.shared) -> Webservice {
            
            let webservice = Webservice(baseURL: URL(string: baseURL)!,
                                        unauthorizedResponseHandler: authorizationHandler,
                                        defaultHeaders: defaultHeaders,
                                        session: session)
            
            webservices[baseURL] = webservice
            
            return webservice
        }
        
        public static func baseURL(_ baseURL: String) -> Webservice {
            return webservices[baseURL]!
        }
    }
}
