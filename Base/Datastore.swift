//
//  Datastore.swift
//  NABase
//
//  Created by Wain on 27/09/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

import CoreData

public final class Datastore {
    
    //MARK: Core Data
    
    public func newEditingContext(autoSaveParent: Bool = false) -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = self.viewContext
        
        if autoSaveParent {
            NotificationCenter.default.addObserver(self, selector: #selector(mocDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: moc)
        }
        
        return moc
    }
    
    public func viewManagedObjectContext() -> NSManagedObjectContext {
        return self.viewContext
    }
    
    private var viewContext: NSManagedObjectContext
    
    public init(withModelURL modelURL: URL, documentURL: URL?, autoMigrate: Bool = false, isReady: (() -> Void)? = nil) {
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        viewContext.persistentStoreCoordinator = psc
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            if let documentURL = documentURL {
                
                BaseLog.coreData.log(.trace, "Adding store at \(documentURL)")
                
                do {
                    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: documentURL, options: nil)
                } catch {
                    BaseLog.coreData.log(.error, "Error trying to load the store: \(error)\nDeleting and starting fresh...")
                    
                    if autoMigrate {
                        do {
                            try FileManager.default.removeItem(at: documentURL)
                            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: documentURL, options: nil)
                        } catch {
                            fatalError("Error migrating store: \(error)")
                        }
                    } else {
                        fatalError("Error adding persistent store: \(error)")
                    }
                }
                
                BaseLog.coreData.log(.trace, "Added store")

            } else {
                
                BaseLog.coreData.log(.trace, "Creating in-memory store")
                
                do {
                    try psc.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: documentURL, options: nil)
                } catch {
                    fatalError("Error adding persistent store: \(error)")
                }
            }
            
            if let completion = isReady {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func mocDidSave(note: Notification) {
        if let moc = note.object as? NSManagedObjectContext, moc != viewContext {
            viewContext.perform({
                BaseLog.coreData.log(.trace, "Data loading context saved")
                
                do {
                    try self.viewContext.save()
                } catch {
                    BaseLog.coreData.log(.error, "Error trying to save the store: \(error)")
                }
            })
        }
    }
    
    func injectTestContext(moc: NSManagedObjectContext) {
        self.viewContext = moc
    }
}

