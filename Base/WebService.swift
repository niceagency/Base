//
//  WebService.swift
//  NABase
//
//  Created by Wain on 29/09/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol UnauthorizedResponseHandler {
    func authorizedRequestDidFail(request: URLRequest, response: HTTPURLResponse)
}

public enum LoadResult<T> {
    case success(T)
    case error(Error)
}

public final class Webservice {
    
    let baseURL: URL
    let session: URLSession
    private let unauthorizedResponseHandler: UnauthorizedResponseHandler?
    
    public var behavior: RequestBehavior = EmptyRequestBehavior()
    
    init(baseURL: URL, unauthorizedResponseHandler: UnauthorizedResponseHandler? = nil, session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
        self.unauthorizedResponseHandler = unauthorizedResponseHandler
    }
    
    static let validResponseCodes = [200,201,204]
    
    public func request<A>(_ resource: Resource<A>,
                        withBehavior additionalBehavior: RequestBehavior = EmptyRequestBehavior(),
                        completion: @escaping (LoadResult<A>) -> ()) {
        
        let behavior = CompositeRequestBehavior(behaviors: [ self.behavior, additionalBehavior ])
        
        let request = URLRequest(resource: resource, baseURL: self.baseURL, additionalHeaders: behavior.additionalHeaders)
        
        BaseLog.network.log(.trace, request)
        
        let session = self.session
        let cancel = resource.cancellationPolicy
        
        let matchURL = request.url!
        
        session.getAllTasks { tasks in
            for running in tasks {
                if cancel.matches(url: matchURL, with: running.originalRequest!.url!) {
                    if running.state != .completed && running.state != .canceling {
                        BaseLog.network.log(.trace, "Cancelling \(running) as a result of starting \(request)")
                        running.cancel()
                    }
                }
            }
        }
        
        behavior.beforeSend()
        
        let success: ((A) -> ()) = { result in
            DispatchQueue.main.async {
                completion(.success(result))
                behavior.afterComplete()
            }
        }
        let failure: ((Error) -> ()) = { error in
            DispatchQueue.main.async {
                completion(.error(error))
                behavior.afterFailure(error: error)
            }
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            BaseLog.network.log(.trace, "done")
            
            if let error = error as NSError? {
                let isCancelled = error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
                
                // Surpress all cancelled request errors
                guard !isCancelled else {
                    behavior.afterComplete()
                    return
                }
                
                let noConnectivity = error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet
                
                guard !noConnectivity else {
                    let failingURL = error.userInfo[NSURLErrorFailingURLStringErrorKey]! as! String
                    
                    BaseLog.network.log(.trace, "No connectivity available for request: \(failingURL)")
                    
                    failure(NAError(type: NetworkError.noConnection(error.code, failingURL)))
                    return
                }
            }
            
            if let response = response as? HTTPURLResponse {
                let statusCode = response.statusCode
                
                if !Webservice.validResponseCodes.contains(statusCode) {
                    
                    // Default to an HTTP error in case caller did not provide a response error handler
                    var error: Error = NAError(type: NetworkError.httpError(statusCode))
                    
                    if let errorResponseHandler = resource.errorResponseHandler {
                        let responseError = errorResponseHandler(statusCode, data)
                        
                        if responseError != nil {
                            error = responseError!
                        }
                    }
                    
                    failure(error)
                    
                    if statusCode == 401 {
                        DispatchQueue.main.async {
                            self.unauthorizedResponseHandler?.authorizedRequestDidFail(request: request, response: response)
                        }
                    }
                    
                    return
                }
            }
            
            if let data = data {
                BaseLog.network.log(.trace, "data to parse")
                
                let result = resource.parse(data)
                
                if let value = result.0 {
                    success(value)
                } else if let error = result.1 {
                    failure(error)
                } else {
                    failure(NAError(type: DataError.parse))
                }
            } else {
                BaseLog.network.log(.trace, "no data returned")
                
                failure(error ?? NAError(type: NetworkError.httpError(-1)))
            }
        }
        
        task.resume()
        
        BaseLog.network.log(.trace, "Started \(task) for \(request)")
    }
}

fileprivate extension Resource {
    func url(for baseURL: URL) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.scheme!
        urlComponents.host = baseURL.host
        urlComponents.port = baseURL.port
        urlComponents.path = baseURL.path.appending(self.endpoint)
        
        if let query = self.query, !query.isEmpty {
            urlComponents.queryItems = query
        }
        
        return urlComponents.url!
    }
}

fileprivate extension HttpMethod {
    var name: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .delete: return "DELETE"
        }
    }
    
    func map<B>(f: (Body) -> B) -> HttpMethod<B> {
        switch self {
        case .get(let body):
            if let b = body {
                return .get(f(b))
            }
            return .get(nil)
        case .post(let body):
            if let b = body {
                return .post(f(b))
            }
            return .post(nil)
        case .put(let body):
            if let b = body {
                return .put(f(b))
            }
            return .put(nil)
        case .delete(let body):
            if let b = body {
                return .delete(f(b))
            }
            return .delete(nil)
        }
    }
}

fileprivate extension CancellationPolicy {
    func matches(url: URL, with: URL) -> Bool {
        var cancel: ((URL, URL) -> Bool)!
        
        switch self {
        case .none:
            cancel = { _, _ in
                return false
            }
        case .path:
            cancel = { matchURL, withURL in
                return (matchURL.path == withURL.path)
            }
        case .uri:
            cancel = { matchURL, withURL in
                let match = URLComponents(url: matchURL, resolvingAgainstBaseURL: false)
                let with = URLComponents(url: withURL, resolvingAgainstBaseURL: false)
                
                return (match?.path == with?.path && match?.query == with?.query)
            }
        case .pattern(let pattern):
            cancel = { _, withURL in
                let matchRange = withURL.absoluteString.range(of: pattern, options: .regularExpression, range: nil, locale: nil)
                return (matchRange != nil && !matchRange!.isEmpty)
            }
        }
        
        return cancel(url, with)
    }
}

fileprivate extension URLRequest {
    init<A>(resource: Resource<A>, baseURL: URL, additionalHeaders: [(String, String)]) {
        self.init(url: resource.url(for: baseURL))
        
        let method = resource.method.map { input -> Data in
            if input is Data {
                return input as! Data
            }
            
            return try! JSONSerialization.data(withJSONObject: input, options: [])
        }
        
        httpMethod = method.name
        
        switch method {
        case let .get(data):
            httpBody = data
        case let .post(data):
            httpBody = data
        case let .put(data):
            httpBody = data
        case let .delete(data):
            httpBody = data
        }
        
        if let provider = resource.headerProvider {
            for (header, value) in provider.headers() {
                addValue(value, forHTTPHeaderField: header)
            }
        }
        
        for (header, value) in additionalHeaders {
            addValue(value, forHTTPHeaderField: header)
        }
    }
}
