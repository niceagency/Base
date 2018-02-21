//
//  Datastore.swift
//  NABase
//
//  Created by Wain on 27/09/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation
import CoreData

public enum ContextSavePolicy {
    case none
    case autoSaveToParent(owner: Datastore)
}

public extension NSManagedObjectContext {
    public func backgroundChildContext(savePolicy: ContextSavePolicy = .none) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = self
        
        if case let .autoSaveToParent(datastore) = savePolicy {
            datastore.forwardSaveToParentContexts.append(Weak(moc))
        }
        
        return moc
    }
}

public final class Datastore {
    
    // MARK: Core Data
    fileprivate var forwardSaveToParentContexts = [Weak<NSManagedObjectContext>]()
    
    private let persistentContainer: NSPersistentContainer
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public class var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    public init(modelName: String,
                storePathDirectory: URL? = Datastore.documentsDirectory,
                manualMigration: Bool = false,
                isReady: (() -> Void)? = nil) {
        
        let persistentContainer = NSPersistentContainer(name: modelName)
        
        let description: NSPersistentStoreDescription
        
        if var storePathDirectory = storePathDirectory {
            storePathDirectory.appendPathComponent("\(modelName).sqlite")
            description = NSPersistentStoreDescription(url: storePathDirectory)
            description.shouldInferMappingModelAutomatically = !manualMigration
            description.shouldMigrateStoreAutomatically = !manualMigration
        } else {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        }
        
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { storeDescription, error in
            
            persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            
            BaseLog.coreData.log(.trace, "Loaded persistent store: \(storeDescription)")
            
            if let error = error {
                fatalError("Failed to load persistent stores \(error)")
            }
            
            if let completion = isReady {
                completion()
            }
        }
        
        self.persistentContainer = persistentContainer
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mocDidSave),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func mocDidSave(note: Notification) {
        
        guard let moc = note.object as? NSManagedObjectContext else {
            return
        }
        
        if let userInfo = note.userInfo {
                
            if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                for object in updatedObjects {
                    BaseLog.coreData.log(.trace, "Refreshing \(object) on context: \(moc)")
                    moc.refresh(object, mergeChanges: false)
                }
            }
        }
        
        if forwardSaveToParentContexts.contains(moc),
            let parent = moc.parent {
            parent.perform {
                BaseLog.coreData.log(.trace, "Data loading context saved")
                
                do {
                    try parent.save()
                } catch {
                    BaseLog.coreData.log(.error, "Error trying to save the store: \(error)")
                }
            }
        }
    }
}
