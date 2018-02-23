//
//  Types.swift
//  Base
//
//  Created by Tim Searle on 22/02/2018.
//  Copyright © 2018 Nice Agency. All rights reserved.
//

import Foundation

public protocol Weakly {
    associatedtype Value: AnyObject
    var weak: Weak<Value> { get }
}

extension Weak: Weakly {
    public var weak: Weak<Value> { return self }
}

public extension Array where Element: Weakly, Element.Value: Equatable {
    func contains(_ value: Element.Value) -> Bool {
        return self.contains(where: { $0.weak.value == value })
    }
}

public final class Weak<Value: AnyObject> {
    weak var value: Value?
    
    init(_ value: Value) {
        self.value = value
    }
}

public enum Result<Type> {
    case success(Type)
    case error(Error)
}
