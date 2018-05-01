//
//  RequestBehavior.swift
//  NABase
//
//  Created by Wain on 31/01/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import UIKit

//
// Sample BackgroundTaskBehavior
//

//public final class BackgroundTaskBehavior: RequestBehavior {
//    
//    private let application = UIApplication.shared
//    
//    private var identifier: UIBackgroundTaskIdentifier?
//    
//    public func before(sending: URLRequest) {
//        identifier = application.beginBackgroundTask(expirationHandler: {
//            self.endBackgroundTask()
//        })
//    }
//    
//    public func after(completion: URLResponse?) {
//        endBackgroundTask()
//    }
//    
//    public func after(failure: Error?, retry: () -> Void) {
//        endBackgroundTask()
//    }
//    
//    private func endBackgroundTask() {
//        if let identifier = identifier {
//            application.endBackgroundTask(identifier)
//            self.identifier = nil
//        }
//    }
//}
