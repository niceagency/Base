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
    private var childViewControllers: [Weak<UIViewController>] = []
    
    public convenience init() {
        self.init(navigationController: UINavigationController())
    }
    
    public required init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: 
    
    @discardableResult public func setNavigationController(delegate: UINavigationControllerDelegate,
                                                           overwrite: Bool) -> Bool {
        guard navigationController.delegate == nil || overwrite else { return false }
        
        navigationController.delegate = delegate
        return true
    }
    
    open func pushChild(viewController: UIViewController, animated: Bool) {
        navigationController.pushViewController(viewController, animated: animated)
        
        childViewControllers.append(Weak(viewController))
        
        destroyCompleteChildren()
    }
    
    open func present(viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController.present(viewController, animated: animated, completion: completion)
        
        childViewControllers.append(Weak(viewController))
        
        destroyCompleteChildren()
    }
    
    open func noteDidReturn(child: UIViewController) {
        childViewControllers.append(Weak(child))
        
        destroyCompleteChildren()
    }
    
    // MARK: 
    
    open func destroyCompleteChildren() {
        childCoordinators.forEach({ $0.selfDestructIfPossible() })
    }
    
    open func selfDestructIfPossible() {
        destroyCompleteChildren()
        
        if childViewControllers.flatMap({ $0.value }).isEmpty {
            notifyCompletion()
        }
    }
    
    // MARK: 
    
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
    
    // MARK: 
    
    open func notifyCompletion() {
        parent?.didComplete(child: self)
    }
    
    open func didComplete(child: Coordinator) {
        remove(child: child)
    }
}
