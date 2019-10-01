//
//  DataController.swift
//  VirtualTourist
//
//  Created by Justin Kampen on 3/27/19.
//  Copyright © 2019 Justin Kampen. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    // MARK: - Setup Core Data Stack
    
    let persistentController: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentController.viewContext
    }
    
    init(modelName: String) {
        persistentController = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentController.loadPersistentStores { storeDescrition, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            completion?()
        }
    }
}

// MARK: - Setup Save View Context

extension DataController {
    
    func autoSaveViewContext(interval: TimeInterval = 30) {
        guard interval > 0 else {
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
