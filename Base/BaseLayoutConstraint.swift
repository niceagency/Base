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
        
        var parent: UIView?
        var constraints: [NSLayoutConstraint] = []
        
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
        
        guide.identifier = self.identifier ?? "?.?"
        
        superview.addLayoutGuide(guide)
        
        if let view1 = self.firstItem as? UIView {
            switch self.firstAttribute {
            case .left:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.leftAnchor))
            case .right:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.rightAnchor))
            case .top:
                constraints.append(guide.topAnchor.constraint(equalTo: view1.topAnchor))
            case .bottom:
                constraints.append(guide.topAnchor.constraint(equalTo: view1.bottomAnchor))
            case .leading:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.leadingAnchor))
            case .trailing:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.trailingAnchor))
            case .leftMargin:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.layoutMarginsGuide.leftAnchor))
            case .rightMargin:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.layoutMarginsGuide.rightAnchor))
            case .topMargin:
                constraints.append(guide.topAnchor.constraint(equalTo: view1.layoutMarginsGuide.topAnchor))
            case .bottomMargin:
                constraints.append(guide.topAnchor.constraint(equalTo: view1.layoutMarginsGuide.bottomAnchor))
            case .leadingMargin:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.layoutMarginsGuide.leadingAnchor))
            case .trailingMargin:
                constraints.append(guide.leadingAnchor.constraint(equalTo: view1.layoutMarginsGuide.trailingAnchor))
            default:
                assertionFailure("Invalid attribute supplied")
                return
            }
        } else if let guide1 = self.firstItem as? UILayoutGuide {
            switch self.firstAttribute {
            case .left:
                constraints.append(guide.leadingAnchor.constraint(equalTo: guide1.leftAnchor))
            case .right:
                constraints.append(guide.leadingAnchor.constraint(equalTo: guide1.rightAnchor))
            case .top:
                constraints.append(guide.topAnchor.constraint(equalTo: guide1.topAnchor))
            case .bottom:
                constraints.append(guide.topAnchor.constraint(equalTo: guide1.bottomAnchor))
            case .leading:
                constraints.append(guide.leadingAnchor.constraint(equalTo: guide1.leadingAnchor))
            case .trailing:
                constraints.append(guide.leadingAnchor.constraint(equalTo: guide1.trailingAnchor))
            default:
                assertionFailure("Invalid attribute supplied")
                return
            }
        } else {
            assertionFailure("Not connected to a view or a layout guide")
            return
        }
        
        if let view2 = self.secondItem as? UIView {
            if parent == nil {
                parent = view2.superview
            }
            
            switch self.secondAttribute {
            case .left:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.leftAnchor))
            case .right:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.rightAnchor))
            case .top:
                constraints.append(guide.bottomAnchor.constraint(equalTo: view2.topAnchor))
            case .bottom:
                constraints.append(guide.bottomAnchor.constraint(equalTo: view2.bottomAnchor))
            case .leading:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.leadingAnchor))
            case .trailing:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.trailingAnchor))
            case .leftMargin:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.layoutMarginsGuide.leftAnchor))
            case .rightMargin:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.layoutMarginsGuide.rightAnchor))
            case .topMargin:
                constraints.append(guide.bottomAnchor.constraint(equalTo: view2.layoutMarginsGuide.topAnchor))
            case .bottomMargin:
                constraints.append(guide.bottomAnchor.constraint(equalTo: view2.layoutMarginsGuide.bottomAnchor))
            case .leadingMargin:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.layoutMarginsGuide.leadingAnchor))
            case .trailingMargin:
                constraints.append(guide.trailingAnchor.constraint(equalTo: view2.layoutMarginsGuide.trailingAnchor))
            default:
                assertionFailure("Invalid attribute supplied")
                return
            }
        } else if let guide2 = self.secondItem as? UILayoutGuide {
            switch self.secondAttribute {
            case .left:
                constraints.append(guide.trailingAnchor.constraint(equalTo: guide2.leftAnchor))
            case .right:
                constraints.append(guide.trailingAnchor.constraint(equalTo: guide2.rightAnchor))
            case .top:
                constraints.append(guide.bottomAnchor.constraint(equalTo: guide2.topAnchor))
            case .bottom:
                constraints.append(guide.bottomAnchor.constraint(equalTo: guide2.bottomAnchor))
            case .leading:
                constraints.append(guide.trailingAnchor.constraint(equalTo: guide2.leadingAnchor))
            case .trailing:
                constraints.append(guide.trailingAnchor.constraint(equalTo: guide2.trailingAnchor))
            default:
                assertionFailure("Invalid attribute supplied")
                return
            }
        } else {
            assertionFailure("Not connected to a view or a layout guide")
            return
        }
        
        if let width = equalWidthTo {
            let constraint = guide.widthAnchor.constraint(equalTo: width.guide.widthAnchor)
            
            if width.guide.owningView != nil {
                constraints.append(constraint)
            } else {
                width.altConstraints.append(constraint)
            }
        }
        
        if let height = equalHeightTo {
            let constraint = guide.heightAnchor.constraint(equalTo: height.guide.heightAnchor)
            
            if height.guide.owningView != nil {
                constraints.append(constraint)
            } else {
                height.altConstraints.append(constraint)
            }
        }
        
        constraints.forEach({ $0.isActive = true })
        altConstraints.forEach({ $0.isActive = true })
        
        altConstraints.removeAll()
        
        self.isActive = false
    }
}
