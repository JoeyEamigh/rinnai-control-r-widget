//
//  device.swift
//  iOS
//
//  Created by Joey Eamigh on 4/21/22.
//

import SwiftUI
import CoreData

struct DevicePage: View {
  @StateObject var router: ViewRouter
  let device: Device
  let endDate: (scheduled: Bool, end: Date)
  
  init(router: ViewRouter, device: Device) {
    _router = StateObject(wrappedValue: router)
    self.device = device
    self.endDate = Rinnai.determineEndTime(device)
  }
  
  var body: some View {
    return ScrollView {
      ZStack {
        Color("Background").edgesIgnoringSafeArea(.all)
        VStack {
          RecirculatingView(device.recirculating, endDate)
          if (endDate.scheduled) {
            Text("Rinnai does not allow for changes during a scheduled cycle. Please use the Control-R app to modify schedules.")
              .multilineTextAlignment(.center)
              .padding(.all)
          } else {
            RecirculateButtons(device: device, endDate: endDate)
          }
        }
      }
    }.navigationTitle(device.name ?? "uh oh").navigationBarTitleDisplayMode(.inline)
  }
}

struct EndTimeInfo: View {
  let endDate: (scheduled: Bool, end: Date)
  init(_ endDate: (scheduled: Bool, end: Date)) {
    self.endDate = endDate
  }
  
  var body: some View {
    let text = "Ending At: \(Rinnai.endTimeText(endDate))"
    
    return VStack {
      Text(text).padding(.bottom, 1)
    }
  }
}

struct RecirculateButtons: View {
  let device: Device
  let endDate: (scheduled: Bool, end: Date)
  
  var body: some View {
    VStack {
      HStack {
        RecircButton(0, "OFF", device, endDate)
        RecircButton(5, "5m", device, endDate)
      }
      HStack {
        RecircButton(10, "10m", device, endDate)
        RecircButton(15, "15m", device, endDate)
      }
      HStack {
        RecircButton(30, "30m", device, endDate)
        RecircButton(45, "45m", device, endDate)
      }
      HStack {
        RecircButton(60, "1h", device, endDate)
        RecircButton(90, "1.5h", device, endDate)
      }
      HStack {
        RecircButton(120, "2h", device, endDate)
        RecircButton(150, "2.5h", device, endDate)
      }
      HStack {
        RecircButton(180, "3h", device, endDate)
        RecircButton(300, "5h", device, endDate)
      }
    }
  }
}

struct RecircButton: View {
  let duration: Double
  let label: String
  let device: Device
  let endDate: (scheduled: Bool, end: Date)
  @Environment(\.managedObjectContext) private var db
  
  init(_ duration: Double, _ label: String, _ device: Device, _ endDate: (scheduled: Bool, end: Date)) {
    self.duration = duration
    self.label = label
    self.device = device
    self.endDate = endDate
  }
  
  var body: some View {
    Button(action: {
      Task { await recirculate(duration) }
    }) {
      Text(label).fontWeight(.semibold)
        .frame(width: 100, height: 100)
        .foregroundColor(Color("Secondary"))
        .background(buttonColor())
        .clipShape(Circle())
    }.padding(.horizontal).padding(.vertical, 10)
  }
  
  func buttonColor() -> Color {
    if (duration == 0.0 && !device.recirculating) { return .green }
    if (duration == device.duration) {
      if (!endDate.scheduled && device.recirculating) { return .green }
      return .blue
    }
    return Color("AccentColor")
  }
  
  func recirculate(_ time: Double) async {
    device.recirculating = time == 0.0 ? false : true
    device.duration = time == 0.0 ? device.duration : time
    device.rinnaiLastUpdated = Date()
    device.lastUpdated = Date()
    
    try! db.save()
    
    Widgeter.refresh()
    
    let _ = try! await Rinnai(username: KeychainHelper.i.read(service: "email", account: "rinnai", type: String.self)!).setRecirculation(device, duration)
  }
}

struct RecirculatingView: View {
  let recirculating: Bool
  let endDate: (scheduled: Bool, end: Date)
  
  init(_ recirculating: Bool, _ endDate: (scheduled: Bool, end: Date)) {
    self.recirculating = recirculating
    self.endDate = endDate
  }
  
  var body: some View {
    if (recirculating) {
      return VStack {
        Text("Recirculating").font(.largeTitle).padding(.top, 20)
        if (recirculating) { EndTimeInfo(endDate) }
        Image(systemName: "arrow.triangle.2.circlepath.circle.fill").foregroundColor(.green).font(.custom("exL", size: 60))
      }
    } else {
      return VStack {
        Text("Not Recirculating").font(.largeTitle).padding(.top, 20)
        if (recirculating) { EndTimeInfo(endDate) }
        Image(systemName: "exclamationmark.arrow.triangle.2.circlepath").foregroundColor(.gray).font(.custom("exL", size: 60))
      }
    }
  }
}

struct device_Previews: PreviewProvider {
  static let context = PersistenceController.preview.container.viewContext
  
  static var previews: some View {
    let dummyDevice = Device(context: context)
    dummyDevice.id = "1234"
    dummyDevice.name = "Test Device"
    dummyDevice.lastUpdated = Date()
    dummyDevice.rinnaiLastUpdated = Calendar.current.date(byAdding: .minute, value: -45, to: Date())
    dummyDevice.duration = 45.0
    dummyDevice.recirculating = true
    dummyDevice.timezone = "EST"
    
    try? context.save()
    
    return Group {
      DevicePage(router: ViewRouter(), device: dummyDevice).preferredColorScheme(.light)
      DevicePage(router: ViewRouter(), device: dummyDevice).environment(\.colorScheme, .dark)
    }
  }
}
