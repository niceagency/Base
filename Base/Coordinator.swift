//
//  Coordinator.swift
//  Base
//
//  Created by Wain on 25/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import UIKit

open class Coordinator {
    public let navigationController: UINavigationController
    
    private weak var parent: Coordinator?
    
    private var childCoordinators: [Coordinator] = []
    private var childViewControllers: [WeakViewController] = [] 
    
    public convenience init() {
        self.init(navigationController: UINavigationController())
    }
    
    public required init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    //MARK:
    
    @discardableResult public func setNavigationController(delegate: UINavigationControllerDelegate, overwrite: Bool) -> Bool {
        guard navigationController.delegate == nil || overwrite else { return false }
        
        navigationController.delegate = delegate
        return true
    }
    
    open func pushChild(viewController vc: UIViewController, animated: Bool) {
        navigationController.pushViewController(vc, animated: animated)
        
        childViewControllers.append(WeakViewController(vc: vc))
        
        destroyCompleteChildren()
    }
    
    open func present(viewController vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController.present(vc, animated: animated, completion: completion)
        
        childViewControllers.append(WeakViewController(vc: vc))
        
        destroyCompleteChildren()
    }
    
    open func noteDidReturn(child vc: UIViewController) {
        childViewControllers.append(WeakViewController(vc: vc))
        
        destroyCompleteChildren()
    }
    
    //MARK:
    
    open func destroyCompleteChildren() {
        childCoordinators.forEach({ $0.selfDestructIfPossible() })
    }
    
    open func selfDestructIfPossible() {
        destroyCompleteChildren()
        
        if !childViewControllers.contains(where: { $0.isValid }) {
            guard childCoordinators.isEmpty else { return }
            
            notifyCompletion()
        }
    }
    
    //MARK:
    
    open func add(child: Coordinator) {
        child.parent = self
        childCoordinators.append(child)
        
       
    }
    
    private func remove(child: Coordinator) {
        if let index = childCoordinators.index(where: { $0 === child }) {
            childCoordinators.remove(at: index)
        }
        
        selfDestructIfPossible()
    }
    
    //MARK:
    
    open func notifyCompletion() {
        parent?.didComplete(child: self)
    }
    
    open func didComplete(child: Coordinator) {
        remove(child: child)
    }
}

private final class WeakViewController {
    private weak var proxy: UIViewController?
    
    init(vc: UIViewController) {
        proxy = vc
    }
    
    var isValid: Bool {
        return proxy != nil
    }
}
