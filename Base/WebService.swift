//
//  WebService.swift
//  NABase
//
//  Created by Wain on 29/09/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol UnauthorizedResponseHandler {
    func authorizedRequestDidFail(request: URLRequest, response: HTTPURLResponse, data: Data?, retry: @escaping () -> Void)
}

struct DataTaskCallback<A> {
    let success: (URLResponse?, A) -> Void
    let failure: (Error) -> Void
    let networkFailure: (NAError<NetworkError>) -> Void
    let retry: () -> Void
    var unauthorizedResponseHandler: UnauthorizedResponseHandler?
}

extension NSError {
    fileprivate func isCancelledError() -> Bool {
        return self.domain == NSURLErrorDomain && self.code == NSURLErrorCancelled
    }
    
    fileprivate func isNoConnectivityError() -> Bool {
        return self.domain == NSURLErrorDomain && self.code == NSURLErrorNotConnectedToInternet
    }

    fileprivate func isTimeoutError() -> Bool {
        return self.domain == NSURLErrorDomain && self.code == NSURLErrorTimedOut
    }
}

extension URLSession {
    
    private func handleErrorFor<A>( // swiftlint:disable:this function_parameter_count
        error: Error?,
        data: Data?,
        request: URLRequest,
        response: HTTPURLResponse,
        resource: Resource<A>,
        callbacks: DataTaskCallback<A>) {
        // Default to an HTTP error in case caller did not provide a response error handler
        var error: Error = NAError(type: NetworkError.httpError(response.statusCode),
                                   internalError: error)
        
        if let errorResponseHandler = resource.errorResponseHandler {
            
            guard let errorData = HTTPErrorData(responseCode: response.statusCode, data: data) else {
                fatalError("invalid Error response code")
            }
            
            if let responseError = errorResponseHandler(errorData) {
                error = responseError
            }
        }
        
        if Webservice.ResponseCodes.authFailure.contains(response.statusCode), let handler = callbacks.unauthorizedResponseHandler {
            DispatchQueue.main.async {
                handler.authorizedRequestDidFail(request: request, response: response, data: data, retry: callbacks.retry)
            }
        } else {
            callbacks.failure(error)
        }
    }
    
    fileprivate func resourceDataTask<A>(
        request: URLRequest,
        resource: Resource<A>,
        behavior: RequestBehavior,
        callbacks: DataTaskCallback<A>) -> URLSessionDataTask {
        
        return self.dataTask(with: request) { data, response, error in
            BaseLog.network.log(.trace, "done")
            
            if let error = error as NSError? {
                if error.isCancelledError() {
                    return
                }
                
                if error.isNoConnectivityError() || error.isTimeoutError() {
                    let failingURL = error.userInfo[NSURLErrorFailingURLStringErrorKey] ?? "Unknown URL"
                    BaseLog.network.log(.trace, "No connectivity available for request: \(failingURL)")
                    callbacks.networkFailure(NAError(type: NetworkError.noConnection(error.code, "\(failingURL)")))
                    return
                }
            }
            
            if let response = response as? HTTPURLResponse {
                let statusCode = response.statusCode
                
                if !Webservice.ResponseCodes.valid.contains(statusCode) {
                    self.handleErrorFor(error: error,
                                        data: data,
                                        request: request,
                                        response: response,
                                        resource: resource,
                                        callbacks: callbacks)
                    return
                }
            }
            
            if let data = data {
                BaseLog.network.log(.trace, "data to parse")
                
                let result = resource.parse(data, withDecoder: resource.decoder)
                
                switch result {
                case .success(let value):
                    callbacks.success(response, value)
                case .error(let error):
                    callbacks.failure(error)
                }
            } else {
                BaseLog.network.log(.trace, "no data returned")
                
                callbacks.failure(error ?? NAError(type: NetworkError.httpError(-1)))
            }
        }
    }
}

public final class Webservice {
    
    fileprivate struct ResponseCodes {
        static let valid = [200, 201, 204]
        static let authFailure = [401]
    }
    
    public let baseURL: URL
    public let session: URLSession
    private let unauthorizedResponseHandler: UnauthorizedResponseHandler?
    private let defaultHeaders: HeaderProvider?
    
    public var behavior: RequestBehavior = EmptyRequestBehavior()
    
    init(baseURL: URL,
         unauthorizedResponseHandler: UnauthorizedResponseHandler? = nil,
         defaultHeaders: HeaderProvider? = nil,
         session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
        self.unauthorizedResponseHandler = unauthorizedResponseHandler
        self.defaultHeaders = defaultHeaders
    }
    
    public func request<A>(_ resource: Resource<A>, // swiftlint:disable:this function_body_length
                           withBehavior additionalBehavior: RequestBehavior? = nil,
                           networkFailure: ((NAError<NetworkError>) -> Void)? = nil,
                           completion: @escaping (Result<A>) -> Void) {
        
        let behavior = self.behavior.adding(additionalBehavior ?? EmptyRequestBehavior())
        let headers = self.defaultHeaders?.headers() ?? []
        
        guard let plannedRequest = URLRequest(resource: resource,
                                              baseURL: self.baseURL,
                                              additionalHeaders: headers,
                                              requestBehaviour: behavior) else {
                                                DispatchQueue.main.async { completion(.error(NAError<NetworkError>(type: .malformedURL))) }
                                                return
        }
        
        BaseLog.network.log(.trace, plannedRequest)
        
        let request = behavior.modify(planned: plannedRequest) 
        
        if request != plannedRequest { BaseLog.network.log(.trace, request) }
        
        let session = self.session
        let cancel = resource.cancellationPolicy
        
        let matchURL = request.url!
        
        session.getAllTasks { tasks in
            tasks
                .filter { cancel.matches(url: matchURL, with: $0.originalRequest!.url!) }
                .filter { $0.state != .completed && $0.state != .canceling }
                .forEach {
                    BaseLog.network.log(.trace, "Cancelling \($0) as a result of starting \(request)")
                    $0.cancel()
                }
        }
        
        behavior.before(sending: request)
        
        let retry = { self.request(resource, withBehavior: behavior, completion: completion) }
        
        let success: ((URLResponse?, A) -> Void) = { response, result in
            DispatchQueue.main.async {
                completion(.success(result))
                behavior.after(completion: response)
            }
        }
        
        let failure: ((Error) -> Void) = { error in
            DispatchQueue.main.async {
                completion(.error(error))
                behavior.after(failure: error, retry: retry)
            }
        }

        let networkError: ((NAError<NetworkError>) -> Void) = { error in
            DispatchQueue.main.async {
                networkFailure?(error)
                behavior.after(failure: error, retry: retry)
            }
        }
        
        let task = session.resourceDataTask(request: request,
                                            resource: resource,
                                            behavior: behavior,
                                            callbacks: DataTaskCallback(success: success,
                                                                        failure: failure,
                                                                        networkFailure: networkError,
                                                                        retry: retry,
                                                                        unauthorizedResponseHandler: unauthorizedResponseHandler))
        task.resume()
        
        BaseLog.network.log(.trace, "Started \(task) for \(request)")
    }
}

fileprivate extension Resource {
    func urlComponents(for baseURL: URL) -> URLComponents {
        return URLComponents()
            .modifying(scheme: baseURL.scheme)
            .modifying(host: baseURL.host)
            .modifying(port: baseURL.port)
            .modifying(path: baseURL.path.appending(self.endpoint))
            .replacing(queryItems: self.query)
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

internal extension URLRequest {
    init?<A>(resource: Resource<A>, baseURL: URL, additionalHeaders: [(String, String)], requestBehaviour: RequestBehavior) {
        
        guard let url = requestBehaviour.modify(urlComponents: resource.urlComponents(for: baseURL)).url else {
            return nil
        }
        
        self.init(url: url)
        
        let method = resource.method
        
        httpMethod = method.name
        
        switch method {
        case let .get(data):
            httpBody = data?.encoded()
        case let .post(data):
            httpBody = data?.encoded()
        case let .put(data):
            httpBody = data?.encoded()
        case let .delete(data):
            httpBody = data?.encoded()
        case let .patch(data):
            httpBody = data?.encoded()
        }
        
        let headers = (resource.headerProvider?.headers() ?? []) + additionalHeaders
        
        for (header, value) in headers {
            addValue(value, forHTTPHeaderField: header)
        }
    }
}
