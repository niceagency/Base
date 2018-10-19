//
//  View+AutoLayout.swift
//  Base
//
//  Created by Wain on 25/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

#if os(iOS)
import UIKit
typealias View = UIView
#else
import Cocoa
typealias View = NSView
#endif

public protocol Constrainable {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
    var firstBaselineAnchor: NSLayoutYAxisAnchor { get }
    var lastBaselineAnchor: NSLayoutYAxisAnchor { get }
    
    #if os(iOS)
    var layoutMarginsGuide: UILayoutGuide { get }
    var readableContentGuide: UILayoutGuide { get }
    
    @available(iOS 11.0, *)
    var safeAreaLayoutGuide: UILayoutGuide { get }
    #endif
}
public typealias ConstrainedSuperview = Constrainable

extension View: Constrainable {}

public typealias ConstraintExpression = (_ make: Constrainable, _ superview: ConstrainedSuperview) -> [NSLayoutConstraint]

public extension View {
    public func constrain(by constrain: ConstraintExpression) {
        guard let superview = self.superview else {
            assertionFailure("Views need to have a superview to be constrained")
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        let activations = constrain(self, superview)
        
        activations.forEach { $0.isActive = true }
    }
}
