//
//  RequestBehavior.swift
//  NABase
//
//  Created by Wain on 31/01/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import UIKit

public final class BackgroundTaskBehavior: RequestBehavior {
    
    private let application = UIApplication.shared
    
    private var identifier: UIBackgroundTaskIdentifier?
    
    public func beforeSend(ofRequest: URLRequest) {
        identifier = application.beginBackgroundTask(expirationHandler: {
            self.endBackgroundTask()
        })
    }
    
    public func afterComplete(withResponse: URLResponse?) {
        endBackgroundTask()
    }
    
    public func afterFailure(error: Error?, retry: () -> Void) {
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if let identifier = identifier {
            application.endBackgroundTask(identifier)
            self.identifier = nil
        }
    }
}

public final class NetworkActivityIndicatorBehavior: RequestBehavior {
    
    class ActivityIndicatorState {
        var counter = 0 {
            didSet {
                UIApplication.shared.isNetworkActivityIndicatorVisible = self.counter == 0
            }
        }
    }
    
    static let state = ActivityIndicatorState()
    
    public func beforeSend(ofRequest: URLRequest) {
        NetworkActivityIndicatorBehavior.state.counter += 1
    }
    
    public func afterComplete(withResponse: URLResponse?) {
        NetworkActivityIndicatorBehavior.state.counter -= 1
    }
    
    public func afterFailure(error: Error?, retry: () -> Void) {
        NetworkActivityIndicatorBehavior.state.counter -= 1
    }
}
