//
//  info.swift
//  iOS
//
//  Created by Joey Eamigh on 4/24/22.
//

import SwiftUI

struct InfoPage: View {
  @StateObject var router: ViewRouter
  var body: some View {
    ScrollView {
      ZStack {
        Color("Background")
        VStack {
          Text("© Copyright \(String(Date().year)) Joey Eamigh").padding().fixedSize(horizontal: false, vertical: true)
          Text("This app was made for fun since the Rinnai Control-R app is difficult to use, and has no iOS 14+ widgets.").multilineTextAlignment(.center).padding().fixedSize(horizontal: false, vertical: true)
          Text("I also wanted to learn SwiftUI, which was quite the experience.").multilineTextAlignment(.center).padding().fixedSize(horizontal: false, vertical: true)
          Text("The code is open source at\n[github.com/JoeyEamigh/rinnai-control-r-widget](https://github.com/JoeyEamigh/rinnai-control-r-widget)").fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.center).padding()
          Text("THIS APP HAS NO AFFILIATION WITH RINNAI").padding().fixedSize(horizontal: false, vertical: true)
        }
      }
    }.navigationTitle("Application Information").navigationBarTitleDisplayMode(.inline).accentColor(.blue)
  }
}

struct info_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      InfoPage(router: ViewRouter()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
      InfoPage(router: ViewRouter()).environment(\.colorScheme, .dark).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
  }
}
