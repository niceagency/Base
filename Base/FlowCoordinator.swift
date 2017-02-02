//
//  Coordinator.swift
//  NABase
//
//  Created by Tim Searle on 18/01/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import UIKit

public protocol FlowCoordinator: class {
    init(navigationController: UINavigationController, dataStore: Datastore)
}
