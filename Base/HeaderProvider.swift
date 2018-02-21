//
//  HeaderProvider.swift
//  NABase
//
//  Created by Tim Searle on 20/12/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol HeaderProvider {
    func and(_ provider: HeaderProvider) -> HeaderProvider
    func headers() -> [(String, String)]
}

public class CompositeHeaderProvider: HeaderProvider {
    private var providers: [HeaderProvider] = []
    
    public func and(_ provider: HeaderProvider) -> HeaderProvider {
        self.providers.append(provider)
        
        return self
    }
    
    public func headers() -> [(String, String)] {
        return self.providers.flatMap({ $0.headers() })
    }
}

public class SimpleHeaderProvider: CompositeHeaderProvider {
    private let provide: (() -> [(String, String)])
    
    public init(provide: @escaping (() -> [(String, String)])) {
        self.provide = provide
    }
    
    public override func headers() -> [(String, String)] {
        let other = super.headers()
        let mine = self.provide()
        
        return other + mine
    }
}

public struct HTTPHeaders {
    
    public static var jsonContent: HeaderProvider {
        return SimpleHeaderProvider {
            return [("Content-Type", "application/json; charset=utf-8")]
        }
    }
    
    public static var formContent: HeaderProvider {
        return SimpleHeaderProvider {
            return [("Content-Type", "application/x-www-form-urlencoded")]
        }
    }
    
    public static var plainTextContent: HeaderProvider {
        return SimpleHeaderProvider {
            return [("Content-Type", "plain/text")]
        }
    }
}
