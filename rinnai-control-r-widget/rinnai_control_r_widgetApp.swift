//
//  rinnai_control_r_widgetApp.swift
//  rinnai-control-r-widget
//
//  Created by Joey Eamigh on 4/18/22.
//

import SwiftUI

@main
struct rinnai_control_r_widgetApp: App {
  @StateObject var viewRouter : ViewRouter
  let persistenceController = PersistenceController.i
  
  // this init function is used to happily route
  init() {
    print("init fired")
    let router = ViewRouter()
    let email = KeychainHelper.i.read(service: "email", account: "rinnai", type: String.self)
    if (email != nil) {
      print("email found")
      router.currentPage = .devices
      Task {
        await updateDevices()
      }
    }
    _viewRouter = StateObject(wrappedValue: router)
  }
  
  var body: some Scene {
    WindowGroup {
      MotherView(router: viewRouter).environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
  }
}

func updateDevices() async -> Bool {
  let email = KeychainHelper.i.read(service: "email", account: "rinnai", type: String.self)
  if (email != nil) {
    return try! await Rinnai(username: email!).getDevices()
  }
  return false
}
