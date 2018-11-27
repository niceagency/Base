//
//  Network.swift
//  NABase
//
//  Created by Tim Searle on 16/11/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public struct Network {
    
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
