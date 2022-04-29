//
//  ContentView.swift
//  rinnai-control-r-widget
//
//  Created by Joey Eamigh on 4/18/22.
//

import SwiftUI

enum Page {
  case login
  case devices
}

// "mother view"
struct MotherView: View {
  @State var currentPage: Page = .login
  @StateObject var viewRouter: ViewRouter
  
  init(viewRouter: ViewRouter) {
    _viewRouter = StateObject(wrappedValue: viewRouter)
    if (KeychainHelper.i.read(service: "email", account: "rinnai", type: String.self) != nil) {
      print("email found")
      currentPage = .devices
    }
  }
  
  
  var body: some View {
    switch currentPage {
    case .login:
      LoginPage()
    case .devices:
      ZStack {}
    }
  }
}

class ViewRouter: ObservableObject {
  @Published var currentPage: Page = .login
  
}
