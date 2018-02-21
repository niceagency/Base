//
//  TestURLSession.swift
//  Base
//
//  Created by Wain on 04/12/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public struct URLMatch {
    public let host: String
    public let path: String
    public let query: [URLQueryItem]?
    public let method: HttpMethod<Any>
    
    public init(method: HttpMethod<Any>, host: String, path: String, query: [URLQueryItem]?) {
        self.host = host
        self.path = path
        self.query = query
        self.method = method
    }
}

public struct URLResponseStub {
    public let statusCode: Int
    public let headers: [String: String]?
    public let payloadFileName: String?
    
    public init(statusCode: Int, headers: [String: String]?, payloadFileName: String?) {
        self.statusCode = statusCode
        self.headers = headers
        self.payloadFileName = payloadFileName
    }
} 

public struct TestURLSessionConfiguration {
    public let matchingConfig: [URLMatch: URLResponseStub]
    
    public init(config: [URLMatch: URLResponseStub]) {
        matchingConfig = config
    }
    
    init(environmentVariable json: String) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: json.data(using: .utf8)!,
                                                                 options: []),
            let representation = jsonObject as? [[String: [String: Any]]] else {
                fatalError("Unable to serialize JSON object from \(json)")
        }
        
        var config: [URLMatch: URLResponseStub] = [:]
        
        for item in representation {
            let matchRep = item["match"]!
            let stubRep = item["stub"]!
            
            let match = URLMatch(environmentRepresentation: matchRep)
            let stub = URLResponseStub(environmentRepresentation: stubRep)
            
            config[match] = stub
        }
        
        matchingConfig = config
    }
    
    public func environmentRepresentation() -> String {
        var representation: [[String: Any]] = []
        
        for (key, value) in matchingConfig {
            let item: [String: Any] = [
                "match": key.environmentRepresentation(),
                "stub": value.environmentRepresentation()
            ]
            
            representation.append(item)
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: representation, options: []) {
            return String(data: data, encoding: .utf8) ?? ""
        }
        
        return ""
    }
    
    func config(matchingURLRequest request: URLRequest) -> URLResponseStub {
        guard let url = request.url, let method = request.httpMethod else {
            let message =
            """
            URLRequest to match is missing URL or httpMethod
            url: \(String(describing: request.url))
            method: \(String(describing: request.httpMethod))
            """
            
            BaseLog.testSupport.log(.error, message)
            fatalError(message)
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        for (key, value) in matchingConfig where
            key.method.name == method &&
                key.host == components.host &&
                key.path == components.path &&
                key.query?.count == components.queryItems?.count {
                    
                    var fullMatch = true
                    
                    if let matchQuery = key.query, !matchQuery.isEmpty,
                        let testQuery = components.queryItems {
                        for item in matchQuery {
                            fullMatch = fullMatch && testQuery.contains(item)
                        }
                    }
                    
                    if fullMatch {
                        return value
                    }
        }
        
        let message =
        """
        Test URLRequest does not match actual URLRequest
        method: \(method)
        host: \(String(describing: components.host))
        path: \(components.path)
        queries: \(String(describing: components.queryItems))"
        """
        
        BaseLog.testSupport.log(.error, message)
        fatalError(message)
    }
}

final class StubURLSessionDataTask: URLSessionDataTask {
    
    let responseStub: URLResponseStub
    let handler: (Data?, URLResponse?, Error?) -> Void
    
    private let stubURLResponse: URLResponse
    
    override var response: URLResponse? {
        return stubURLResponse
    }
    
    init(url: URL, response responseStub: URLResponseStub, handler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.responseStub = responseStub
        self.handler = handler
        
        self.stubURLResponse = HTTPURLResponse(url: url,
                                               statusCode: responseStub.statusCode,
                                               httpVersion: "1.1",
                                               headerFields: responseStub.headers)!
    }
    
    override func resume() {
        var data: Data?
        
        if let payloadFileName = self.responseStub.payloadFileName {
            let parts = payloadFileName.split(separator: ".")
            
            guard let url = Bundle.main.url(forResource: String(parts[0]),
                                            withExtension: String(parts[1]),
                                            subdirectory: "TestStubDataFiles") else {
                                                let message = "Invalid path for test payload file '\(payloadFileName)'"
                                                BaseLog.testSupport.log(.error, message)
                                                fatalError(message)
            }
            
            data = try? Data(contentsOf: url)
        }
        
        handler(data ?? "".data(using: .utf8), self.stubURLResponse, nil)
    }
}

final class TestURLSession: URLSession {
    
    private let testMapping: TestURLSessionConfiguration
    
    init(testMapping: TestURLSessionConfiguration) {
        self.testMapping = testMapping
    }
    
    override func getAllTasks(completionHandler: @escaping ([URLSessionTask]) -> Void) {
        completionHandler([])
    }
    
    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let url = request.url!
        let stubResponse = testMapping.config(matchingURLRequest: request)
        let task = StubURLSessionDataTask(url: url, response: stubResponse, handler: completionHandler)
        return task
    }
}

// MARK: -

func ==<T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
    switch (lhs, rhs) {
    case (.some(let lhs), .some(let rhs)):
        return lhs == rhs
    case (.none, .none):
        return true
    default:
        return false
    }
}

extension URLMatch: Hashable {
    public var hashValue: Int {
        return host.hashValue ^ path.hashValue
    }
    
    public static func == (lhs: URLMatch, rhs: URLMatch) -> Bool {
        return lhs.host == rhs.host &&
            lhs.path == rhs.path &&
            lhs.query == rhs.query
    }
}

// MARK: -

protocol EnvironmentRepresentable {
    init(environmentRepresentation: [String: Any])
    func environmentRepresentation() -> [String: Any]
}

private extension HttpMethod {
    static func from(methodName name: String) -> HttpMethod {
        switch name {
        case "GET":
            return .get(nil)
        case "POST":
            return .post(nil)
        case "PUT":
            return .put(nil)
        case "DELETE":
            return .delete(nil)
        case "PATCH":
            return .patch(nil)
        default:
            let message = "Invalid HttpMethod supplied: \(name)"
            BaseLog.testSupport.log(.error, message)
            fatalError(message)
        }
    }
}

extension URLMatch: EnvironmentRepresentable {
    init(environmentRepresentation rep: [String: Any]) {
        
        guard let host = rep["host"] as? String,
            let path = rep["path"] as? String else {
                fatalError("Environment representation invalid: \(rep)")
        }
        
        self.host = host
        self.path = path
        method = HttpMethod.from(methodName: (rep["method"] as? String) ?? "")
        let items = rep["query"] as? [[String]]
        
        query = items?.map({ URLQueryItem(name: $0[0], value: $0[1]) }) 
    }
    
    func environmentRepresentation() -> [String: Any] {
        var rep: [String: Any] = [
            "method": method.name,
            "host": host,
            "path": path
        ]
        
        if let query = query {
            rep["query"] = query.map({ [$0.name, $0.value!] })
        }
        
        return rep
    }
}

extension URLResponseStub: EnvironmentRepresentable {
    init(environmentRepresentation rep: [String: Any]) {
        guard let statusCode = rep["statusCode"] as? Int,
            let headers = rep["headers"] as? [String: String],
            let payloadFileName = rep["payloadFileName"] as? String else {
                fatalError("Environment representation invalid: \(rep)")
        }
        
        self.statusCode = statusCode
        self.headers = headers
        self.payloadFileName = payloadFileName
    }
    
    func environmentRepresentation() -> [String: Any] {
        var rep: [String: Any] = [
            "statusCode": statusCode
        ]
        
        if let headers = headers {
            rep["headers"] = headers
        }
        
        if let payloadFileName = payloadFileName {
            rep["payloadFileName"] = payloadFileName
        }
        
        return rep
    }
}
