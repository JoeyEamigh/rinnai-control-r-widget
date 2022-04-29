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
  case devtools
}

class ViewRouter: ObservableObject {
  @Published var currentPage: Page = .login
}

struct MotherView: View {
  @StateObject var router: ViewRouter
  
  var body: some View {
    switch router.currentPage {
    case .login:
      LoginPage(router: router)
    case .devices:
      DevicesPage(router: router)
    case .devtools:
      DevTools(router: router)
    }
#if DEBUG
      EmptyView().onShake(perform: {
        if (router.currentPage != .devtools) { router.currentPage = .devtools; return }
        router.currentPage = .devices
      })
#endif
  }
}
