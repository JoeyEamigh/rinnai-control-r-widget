//
//  widget.swift
//  widget
//
//  Created by Joey Eamigh on 4/18/22.
//

import WidgetKit
import SwiftUI
import Intents

struct RinnaiEntry: TimelineEntry {
  @Environment(\.widgetFamily) var envSize
  let date: Date
  let configuration: RcRConfigurationIntent
  let loggedIn: Bool
  let device: Device?
  let endDate: (scheduled: Bool, end: Date)?
  let size: WidgetFamily?
  let url: URL
  let snapshot: Bool
  
  init(date: Date, configuration: RcRConfigurationIntent, loggedIn: Bool? = nil, mock: Bool? = nil, size: WidgetFamily? = nil, snapshot: Bool = false) {
    let db = PersistenceController.i.container.viewContext
    self.date = date
    self.configuration = configuration
    self.loggedIn = loggedIn ?? (KeychainHelper.i.read(service: "email", account: "rinnai") != nil)
    var device: Device? = nil
    var endDate: (scheduled: Bool, end: Date)? = nil
    
    if (configuration.Device?.identifier != nil || mock == true) {
      let fetchRequest = Device.fetchRequest()
      var id = configuration.Device?.identifier
      if (mock == true) { id = "1234" }
      fetchRequest.predicate = NSPredicate(format: "id == %@", id!)
      device = try? db.fetch(fetchRequest).first
    }
    
    if (device?.id != nil) {
      endDate = Rinnai.determineEndTime(device!)
    }
    
    self.device = device
    self.endDate = endDate
    self.size = size
    self.url = URL(string: "rC-r://\(device?.id ?? "entry")")!
    self.snapshot = snapshot
  }
}

struct RinnaiWidgetView : View {
  let entry: RinnaiProvider.Entry
  
  var body: some View {
    ZStack {
      Color("Background")
      if (entry.snapshot) {
        switch (entry.size ?? entry.envSize) {
        case .systemSmall:
          VStack {
            Text(entry.device?.name ?? "Preview Device").font(.headline).multilineTextAlignment(.center)
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill").foregroundColor(.green).padding(/*@START_MENU_TOKEN@*/.vertical, -5.0/*@END_MENU_TOKEN@*/).font(.custom("exL", size: 40))
            Text("Recirculating").font(.title2)
            Text("Until \(Rinnai.endTimeText(entry.endDate ?? (true, Calendar.current.date(bySettingHour: 10, minute: 9, second: 0, of: Date())!)))")
              .font(.footnote)
              .padding(.top, -14.0)
          }
        default:
          VStack {
            Link(destination: entry.url) {
              Text(entry.device?.name ?? "Preview Device").font(.title).fontWeight(.semibold).multilineTextAlignment(.center)
              Image(systemName: "arrow.triangle.2.circlepath.circle.fill").foregroundColor(.green).font(.custom("exL", size: 50))
              VStack {
                Text("Recirculating").font(.title)
                Text("Until \(Rinnai.endTimeText(entry.endDate ?? (true, Calendar.current.date(bySettingHour: 10, minute: 9, second: 0, of: Date())!)))").font(.body).padding(.top, -18.0)
              }
            }
          }
        }
      } else if (entry.loggedIn) {
        if (entry.device?.id == nil) {
          Text("Please select a device by long-pressing on this widget and tapping edit widget.")
            .multilineTextAlignment(.center)
            .padding(.all)
        } else {
          switch (entry.size ?? entry.envSize) {
          case .systemSmall:
            if (entry.device?.recirculating == true || Rinnai.isDuringSchedule(entry.device!)) {
              VStack {
                Text(entry.device?.name ?? "Device Name").font(.headline).multilineTextAlignment(.center)
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill").foregroundColor(.green).padding(/*@START_MENU_TOKEN@*/.vertical, -5.0/*@END_MENU_TOKEN@*/).font(.custom("exL", size: 40))
                Text("Recirculating").font(.title2)
                Text("Until \(Rinnai.endTimeText(entry.endDate ?? (true, Date())))")
                  .font(.footnote)
                  .padding(.top, -14.0)
              }
            } else {
              VStack {
                Text(entry.device?.name ?? "Device Name").font(.headline).multilineTextAlignment(.center)
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath").foregroundColor(.gray).padding(/*@START_MENU_TOKEN@*/.vertical, -5.0/*@END_MENU_TOKEN@*/).font(.custom("exL", size: 40))
                Text("Not Recirculating").font(.title2).multilineTextAlignment(.center)
              }
            }
          default:
            if (entry.device?.recirculating == true) {
              VStack {
                Link(destination: entry.url) {
                  Text(entry.device?.name ?? "Device Name").font(.title).fontWeight(.semibold).multilineTextAlignment(.center)
                  Image(systemName: "arrow.triangle.2.circlepath.circle.fill").foregroundColor(.green).font(.custom("exL", size: 50))
                  VStack {
                    Text("Recirculating").font(.title)
                    Text("Until \(Rinnai.endTimeText(entry.endDate ?? (true, Date())))").font(.body).padding(.top, -18.0)
                  }
                }
              }
            } else {
              VStack {
                Link(destination: entry.url) {
                  Text(entry.device?.name ?? "Device Name").font(.title).fontWeight(.semibold).multilineTextAlignment(.center)
                  Image(systemName: "exclamationmark.arrow.triangle.2.circlepath").foregroundColor(.gray).font(.custom("exL", size: 50))
                  Text("Not Recirculating").font(.title).multilineTextAlignment(.center)
                }
              }
            }
          }
        }
      } else {
        Text("Please tap here to log in to your Rinnai Control-R Account")
          .multilineTextAlignment(.center)
          .padding(.all)
          .font(.body)
      }
    }.widgetURL(entry.url)
  }
}

struct RinnaiProvider: IntentTimelineProvider {
  let db = PersistenceController.i.container.viewContext
  
  func placeholder(in context: Context) -> RinnaiEntry {
    RinnaiEntry(date: Date(), configuration: RcRConfigurationIntent(), size: context.family)
  }
  
  func getSnapshot(for configuration: RcRConfigurationIntent, in context: Context, completion: @escaping (RinnaiEntry) -> ()) {
    let entry = RinnaiEntry(date: Date(), configuration: configuration, size: context.family, snapshot: true)
    completion(entry)
  }
  
  func getTimeline(for configuration: RcRConfigurationIntent, in context: Context, completion: @escaping (Timeline<RinnaiEntry>) -> ()) {
    var entries: [RinnaiEntry] = []
    var device: Device?
    
    if (configuration.Device?.identifier != nil) {
      let fetchRequest = Device.fetchRequest()
      let id = configuration.Device?.identifier
      fetchRequest.predicate = NSPredicate(format: "id == %@", id!)
      device = try? db.fetch(fetchRequest).first
    }
    
    entries.append(RinnaiEntry(date: Date(), configuration: configuration, size: context.family))
    
    if (device?.id != nil) {
      for date in Rinnai.startAndEndTimes(device!) {
        entries.append(RinnaiEntry(date: date, configuration: configuration, size: context.family))
      }
    }
  
    
    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)!))
    completion(timeline)
  }
}


@main
struct widget: Widget {
  let kind: String = "com.joeyeamigh.rinnai-control-r-widget.recirculating"
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind,
                        intent: RcRConfigurationIntent.self,
                        provider: RinnaiProvider()
    ) { entry in
      RinnaiWidgetView(entry: entry)
    }
    .configurationDisplayName("Device Selection")
    .description("Select which device to display in the widget")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}


struct widget_Previews: PreviewProvider {
  static let db = PersistenceController.preview.container.viewContext
  
  static var previews: some View {
    let dummyDevice = Device(context: db)
    dummyDevice.id = "1234"
    dummyDevice.name = "Test Device"
    dummyDevice.lastUpdated = Date()
    dummyDevice.rinnaiLastUpdated = Calendar.current.date(byAdding: .minute, value: -45, to: Date())
    dummyDevice.duration = 45.0
    dummyDevice.recirculating = true
    dummyDevice.timezone = "EST"
    
    try? db.save()
    
    return Group {
      RinnaiWidgetView(entry: RinnaiEntry(date: Date(), configuration: RcRConfigurationIntent(), loggedIn: true, mock: true, size: .systemSmall))
        .previewContext(WidgetPreviewContext(family: .systemSmall)).preferredColorScheme(.light)
      RinnaiWidgetView(entry: RinnaiEntry(date: Date(), configuration: RcRConfigurationIntent(), loggedIn: false, mock: true, size: .systemSmall))
        .previewContext(WidgetPreviewContext(family: .systemSmall)).preferredColorScheme(.dark).environment(\.colorScheme, .dark)
      RinnaiWidgetView(entry: RinnaiEntry(date: Date(), configuration: RcRConfigurationIntent(), loggedIn: false, mock: true))
        .previewContext(WidgetPreviewContext(family: .systemMedium)).preferredColorScheme(.light)
      RinnaiWidgetView(entry: RinnaiEntry(date: Date(), configuration: RcRConfigurationIntent(), loggedIn: true, mock: true))
        .previewContext(WidgetPreviewContext(family: .systemMedium)).preferredColorScheme(.dark).environment(\.colorScheme, .dark)
    }
  }
}
