//
//  BaseLayoutConstraint.swift
//  Base
//
//  Created by Wain on 01/05/2018.
//  Copyright © 2018 Nice Agency. All rights reserved.
//

import UIKit

final class BaseLayoutConstraint: NSLayoutConstraint {
    
    private lazy var guide: UILayoutGuide = { UILayoutGuide() }()
    private lazy var altConstraints: [NSLayoutConstraint] = { [] }()
    
    @IBOutlet private var equalWidthTo: BaseLayoutConstraint?
    @IBOutlet private var equalHeightTo: BaseLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guide.identifier = self.identifier ?? "?.?"
        
        self.addLayoutGuide()
        
        if let view1 = self.secondItem as? UIView {
            self.convertToLeadingConstraint(linkedView: view1)
        } else if let guide1 = self.secondItem as? UILayoutGuide {
            self.convertToLeadingConstraint(linkedGuide: guide1)
        } else {
            assertionFailure("Not connected to a view or a layout guide")
            return
        }
        
        if let view2 = self.firstItem as? UIView {
            self.convertToTrailingConstraint(linkedView: view2)
        } else if let guide2 = self.firstItem as? UILayoutGuide {
            self.convertToTrailingConstraint(linkedGuide: guide2)
        } else {
            assertionFailure("Not connected to a view or a layout guide")
            return
        }
        
        self.applySpacingConstraints()
        
        self.isActive = false
    }
    
    // MARK: -
    
    private func addLayoutGuide() {
        var parent: UIView?
        
        if let view1 = self.firstItem as? UIView,
            let view2 = self.secondItem as? UIView {
            guard view1.superview == view2.superview else {
                assertionFailure("Connected 2 views don't have the same superview")
                return
            }
            
            parent = view1.superview
        } else if let view1 = self.firstItem as? UIView {
            parent = view1.superview
        } else if let view2 = self.secondItem as? UIView {
            parent = view2.superview
        }
        
        guard let superview = parent else {
            assertionFailure("Parent superview not located")
            return
        }
        
        superview.addLayoutGuide(guide)
    }
    
    private func convertToLeadingConstraint(linkedView view: UIView) {
        let attr = self.secondAttribute
        
        switch attr {
        case .left,
             .right,
             .leading,
             .trailing:
            guide.leadingAnchor.constraint(equalTo: view.xAxisAnchor(forAttribute: attr)).isActive = true
        case .leftMargin,
             .rightMargin,
             .leadingMargin,
             .trailingMargin:
            guide.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.xAxisAnchor(forAttribute: attr)).isActive = true
        case .top,
             .bottom:
            guide.topAnchor.constraint(equalTo: view.yAxisAnchor(forAttribute: attr)).isActive = true
        case .topMargin,
             .bottomMargin:
            guide.topAnchor.constraint(equalTo: view.layoutMarginsGuide.yAxisAnchor(forAttribute: attr)).isActive = true
        default:
            assertionFailure("Invalid attribute supplied")
            return
        }
    }
    
    private func convertToLeadingConstraint(linkedGuide: UILayoutGuide) { 
        let attr = self.secondAttribute
        
        switch attr {
        case .left,
             .right,
             .leading,
             .trailing:
            guide.leadingAnchor.constraint(equalTo: linkedGuide.xAxisAnchor(forAttribute: attr)).isActive = true
        case .top,
             .bottom:
            guide.topAnchor.constraint(equalTo: linkedGuide.yAxisAnchor(forAttribute: attr)).isActive = true
        default:
            assertionFailure("Invalid attribute supplied")
            return
        }
    }
    
    private func convertToTrailingConstraint(linkedView view: UIView) {
        let attr = self.firstAttribute
        
        switch attr {
        case .left,
             .right,
             .leading,
             .trailing:
            guide.trailingAnchor.constraint(equalTo: view.xAxisAnchor(forAttribute: attr)).isActive = true
        case .leftMargin,
             .rightMargin,
             .leadingMargin,
             .trailingMargin:
            guide.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.xAxisAnchor(forAttribute: attr)).isActive = true
        case .top,
             .bottom:
            guide.bottomAnchor.constraint(equalTo: view.yAxisAnchor(forAttribute: attr)).isActive = true
        case .topMargin,
             .bottomMargin:
            guide.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.yAxisAnchor(forAttribute: attr)).isActive = true
        default:
            assertionFailure("Invalid attribute supplied")
            return
        }
    }
    
    private func convertToTrailingConstraint(linkedGuide: UILayoutGuide) {
        let attr = self.firstAttribute
        
        switch attr {
        case .left,
             .right,
             .leading,
             .trailing:
            guide.trailingAnchor.constraint(equalTo: linkedGuide.xAxisAnchor(forAttribute: attr)).isActive = true
        case .top,
             .bottom:
            guide.bottomAnchor.constraint(equalTo: linkedGuide.yAxisAnchor(forAttribute: attr)).isActive = true
        default:
            assertionFailure("Invalid attribute supplied")
            return
        }
    }
    
    private func applySpacingConstraints() {
        if let width = equalWidthTo {
            let constraint = guide.widthAnchor.constraint(equalTo: width.guide.widthAnchor)
            
            if width.guide.owningView != nil {
                constraint.isActive = true
            } else {
                width.altConstraints.append(constraint)
            }
        }
        
        if let height = equalHeightTo {
            let constraint = guide.heightAnchor.constraint(equalTo: height.guide.heightAnchor)
            
            if height.guide.owningView != nil {
                constraint.isActive = true
            } else {
                height.altConstraints.append(constraint)
            }
        }
        
        altConstraints.forEach({ $0.isActive = true })
        altConstraints.removeAll()
    }
}

// MARK: -

private extension UIView {
    private static let xMapping: [NSLayoutAttribute: ((UIView) -> NSLayoutXAxisAnchor)] = [
        .left: { $0.leftAnchor },
        .right: { $0.rightAnchor },
        .leading: { $0.leadingAnchor },
        .trailing: { $0.trailingAnchor },
        .leftMargin: { $0.leftAnchor },
        .rightMargin: { $0.rightAnchor },
        .leadingMargin: { $0.leadingAnchor },
        .trailingMargin: { $0.trailingAnchor }
    ]
    
    private static let yMapping: [NSLayoutAttribute: ((UIView) -> NSLayoutYAxisAnchor)] = [
        .top: { $0.topAnchor },
        .bottom: { $0.bottomAnchor },
        .topMargin: { $0.topAnchor },
        .bottomMargin: { $0.bottomAnchor }
    ]
    
    func xAxisAnchor(forAttribute attr: NSLayoutAttribute) -> NSLayoutXAxisAnchor {
        guard let anchorMapping = UIView.xMapping[attr] else {
            assertionFailure("Invalid attribute supplied")
            return leadingAnchor
        }
        
        return anchorMapping(self)
    }
    func yAxisAnchor(forAttribute attr: NSLayoutAttribute) -> NSLayoutYAxisAnchor {
        guard let anchorMapping = UIView.yMapping[attr] else {
            assertionFailure("Invalid attribute supplied")
            return topAnchor
        }
        
        return anchorMapping(self)
    }
}

private extension UILayoutGuide {
    private static let xMapping: [NSLayoutAttribute: ((UILayoutGuide) -> NSLayoutXAxisAnchor)] = [
        .left: { $0.leftAnchor },
        .right: { $0.rightAnchor },
        .leading: { $0.leadingAnchor },
        .trailing: { $0.trailingAnchor },
        .leftMargin: { $0.leftAnchor },
        .rightMargin: { $0.rightAnchor },
        .leadingMargin: { $0.leadingAnchor },
        .trailingMargin: { $0.trailingAnchor }
    ]
    
    private static let yMapping: [NSLayoutAttribute: ((UILayoutGuide) -> NSLayoutYAxisAnchor)] = [
        .top: { $0.topAnchor },
        .bottom: { $0.bottomAnchor },
        .topMargin: { $0.topAnchor },
        .bottomMargin: { $0.bottomAnchor }
    ]
    
    func xAxisAnchor(forAttribute attr: NSLayoutAttribute) -> NSLayoutXAxisAnchor {
        guard let anchorMapping = UILayoutGuide.xMapping[attr] else {
            assertionFailure("Invalid attribute supplied")
            return leadingAnchor
        }
        
        return anchorMapping(self)
    }
    func yAxisAnchor(forAttribute attr: NSLayoutAttribute) -> NSLayoutYAxisAnchor {
        guard let anchorMapping = UILayoutGuide.yMapping[attr] else {
            assertionFailure("Invalid attribute supplied")
            return topAnchor
        }
        
        return anchorMapping(self)
    }
}
