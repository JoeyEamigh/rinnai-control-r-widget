//
//  IntentHandler.swift
//  intents
//
//  Created by Joey Eamigh on 4/27/22.
//

import Intents

class IntentHandler: INExtension, RcRConfigurationIntentHandling {
  func provideDeviceOptionsCollection(for intent: RcRConfigurationIntent) async throws -> INObjectCollection<DeviceOption> {
    do {
      let db = PersistenceController.i.container.viewContext
      let fetchRequest = Device.fetchRequest()
      let devices = try db.fetch(fetchRequest)
      let options: [DeviceOption] = devices.map { device in
        return DeviceOption(identifier: device.id!, display: device.name!)
      }
      
      let collection = INObjectCollection(items: options)
      
      return collection
    } catch {
      print("error: \(error)")
      return INObjectCollection(items: [] as [DeviceOption])
    }
  }
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}
