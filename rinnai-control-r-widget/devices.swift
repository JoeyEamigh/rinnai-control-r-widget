//
//  devices.swift
//  iOS
//
//  Created by Joey Eamigh on 4/21/22.
//

import SwiftUI

struct DevicesPage: View {
  @StateObject var router: ViewRouter
  @Environment(\.managedObjectContext) private var db
  @FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Device.lastUpdated, ascending: true)],
    animation: .default)
  private var devices: FetchedResults<Device>
  @State private var selected: String?
  
  func logout() {
    KeychainHelper.i.delete(service: "email", account: "rinnai")
    for device in devices {
      for schedule in (device.schedules?.allObjects ?? []) as! [Schedule] { db.delete(schedule) }
      db.delete(device)
    }
    Widgeter.refresh()
    router.currentPage = .login
  }
  
  var body: some View {
    ZStack {
      Color("Background").edgesIgnoringSafeArea(.all)
      NavigationView {
        List(devices) {
          device in DeviceRow(device: device, router: router, selected: $selected)
        }.navigationBarTitle("Rinnai Devices").navigationBarItems(
          leading: NavigationLink(destination: InfoPage(router: router)) {
            Image(systemName: "info.circle").foregroundColor(.blue)
          },
          trailing:
            Button("Logout") {
              logout()
            }.foregroundColor(.blue)
        ).refreshable {
          _ = await updateDevices()
        }
      }.navigationViewStyle(.stack).accentColor(.blue).onOpenURL { url in
        guard url.scheme == "rC-r" else { return }
        let location = url.absoluteString.replacingOccurrences(of: "rC-r://", with: "")
        print("opened from widget - location: \(location)")
        if (location == "entry") { return }
        selected = location
      }
    }
  }
}

struct DeviceRow: View {
  let device: Device
  @StateObject var router: ViewRouter
  @Binding var selected: String?
  
  var body: some View {
    NavigationLink(destination: DevicePage(router: router, device: device), tag: device.id!, selection: $selected) {
      VStack {
        Text(device.name!).fontWeight(.medium).padding(.bottom, 5).font(.title3)
        HStack {
          Image(systemName: device.recirculating ? "arrow.triangle.2.circlepath.circle.fill" : "exclamationmark.arrow.triangle.2.circlepath").foregroundColor(device.recirculating ? .green : .gray)
          Text(device.recirculating ? "Recirculating" : "Not Recirculating")
        }
      }.padding(.all, 5)
    }
  }
}

struct DevicesPage_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      DevicesPage(router: ViewRouter()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
      DevicesPage(router: ViewRouter()).environment(\.colorScheme, .dark).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
  }
}
