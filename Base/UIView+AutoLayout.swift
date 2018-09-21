//
//  UIView+AutoLayout.swift
//  Base
//
//  Created by Wain on 25/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import UIKit

// MARK: Constrainability

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
    
    func centerIn(_ other: Constrainable, offsetBy offset: UIOffset) -> [NSLayoutConstraint]
    func alignEdgesTo(_ other: Constrainable, insetBy insets: UIEdgeInsets) -> [NSLayoutConstraint]
    func aspectRatio (_  ratio: CGFloat) -> [NSLayoutConstraint]
}
public typealias ConstrainedSuperview = Constrainable

extension Constrainable {
   
    public func centerIn(_ other: Constrainable, offsetBy offset: UIOffset = UIOffset.zero) -> [NSLayoutConstraint] {
        return [
            self.centerYAnchor.constraint(equalTo: other.centerYAnchor, constant: offset.vertical),
            self.centerXAnchor.constraint(equalTo: other.centerXAnchor, constant: offset.horizontal)
        ]
    }
    
    public func alignEdgesTo(_ other: Constrainable, insetBy insets: UIEdgeInsets = UIEdgeInsets.zero) -> [NSLayoutConstraint] {
        
        return [
            self.leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            self.trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: insets.right),
            self.topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            self.bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: insets.bottom)
        ]
    }
    
    public func aspectRatio(_  ratio: CGFloat) -> [NSLayoutConstraint] {
    
        return [
            self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: ratio)
        ]
    }
}

extension UIView: Constrainable {}

// MARK: Collections of constraints

public protocol ActivateableConstraint {
    func activate()
}

extension NSLayoutConstraint: ActivateableConstraint {
    public func activate() {
        isActive = true
    }
}

extension Array: ActivateableConstraint where Element: ActivateableConstraint {
    public func activate() {
        forEach { $0.activate() }
    }
}

// MARK: Constraining

public typealias ConstraintExpression = (_ make: Constrainable, _ superview: ConstrainedSuperview) -> [ActivateableConstraint]

public extension UIView {
    public func constrain(by constrain: ConstraintExpression) {
        guard let superview = self.superview else {
            assertionFailure("Views need to have a superview to be constrained")
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        let activations = constrain(self, superview)
        
        activations.forEach { $0.activate() }
    }
}
