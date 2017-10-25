//
//  UIView+AutoLayout.swift
//  Base
//
//  Created by Wain on 25/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import UIKit

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
    
    var layoutMarginsGuide: UILayoutGuide { get }
    var readableContentGuide: UILayoutGuide { get }
    
    @available(iOS 11.0, *)
    var safeAreaLayoutGuide: UILayoutGuide { get }
}
public typealias ConstrainedSuperview = Constrainable

extension UIView: Constrainable {}

public typealias ConstraintExpression = (_ make: Constrainable, _ superview: ConstrainedSuperview) -> [NSLayoutConstraint]

public extension UIView {
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
