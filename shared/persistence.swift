//
//  persistence.swift
//  iOS
//
//  Created by Joey Eamigh on 4/20/22.
//

import CoreData

struct PersistenceController {
  static let i = PersistenceController()
  let container: NSPersistentContainer
  
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    
    let dummyDevice = Device(context: viewContext)
    dummyDevice.id = "1234"
    dummyDevice.name = "Test Device"
    dummyDevice.lastUpdated = Date()
    dummyDevice.rinnaiLastUpdated = Date()
    dummyDevice.duration = 45.0
    dummyDevice.recirculating = true
    
    do {
      try viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    return result
  }()
  
  init(inMemory: Bool = false) {
    let storeURL = AppGroup.facts.containerURL.appendingPathComponent("World.sqlite")
    let description = NSPersistentStoreDescription(url: storeURL)
    container = NSPersistentContainer(name: "rC-r")
    container.persistentStoreDescriptions = [description]
    
    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        print(error)
        
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        
        fatalError("Unresolved error \(error), \(error)")
      }
    })
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }
  
  func destroyPersistentStore(persistentStoreCoordinator: NSPersistentStoreCoordinator) {
    guard let firstStoreURL = persistentStoreCoordinator.persistentStores.first?.url else {
      print("Missing first store URL - could not destroy")
      return
    }
    
    do {
      try container.persistentStoreCoordinator.destroyPersistentStore(at: firstStoreURL, ofType: NSSQLiteStoreType, options: nil)
    } catch  {
      print("Unable to destroy persistent store: \(error) - \(error.localizedDescription)")
    }
  }
}

