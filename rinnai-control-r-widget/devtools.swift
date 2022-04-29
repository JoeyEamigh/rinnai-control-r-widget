//
//  devtools.swift
//  iOS
//
//  Created by Joey Eamigh on 4/21/22.
//

import SwiftUI
import CoreData

struct DevTools: View {
  @StateObject var router: ViewRouter
  @ObservedObject var notificationManager = LocalNotificationManager()
  @FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Device.lastUpdated, ascending: true)],
    animation: .default)
  private var devices: FetchedResults<Device>
  
  @FetchRequest(
    sortDescriptors: [],
    animation: .default)
  private var schedules: FetchedResults<Schedule>
  
  init(router: ViewRouter) {
    _router = StateObject(wrappedValue: router)
  }
  
  func resetKeychain() {
    KeychainHelper.i.delete(service: "email", account: "rinnai")
    restartApplication()
  }
  
  func restartApplication(){
    self.notificationManager.sendNotification(title: "App Restarted", subtitle: nil, body: "Tap here to relaunch the app", launchIn: 1)
    Thread.sleep(forTimeInterval: 0.5)
    exit(0)
  }
  
  func dumpDevices() {
    print(devices)
  }
  
  func dumpSchedules() {
    print(schedules)
  }
  
  var body: some View {
    ZStack {
      Color("Background").edgesIgnoringSafeArea(.all)
      VStack {
        Text("DevTools").font(.largeTitle).fontWeight(.semibold).padding(.bottom, 40)
        Button(action: dumpSchedules) {
          Text("Dump Schedules").foregroundColor(.white)
            .padding()
            .frame(width: 160, height: 50)
            .background(Color.blue)
            .cornerRadius(10.0).padding(.top, 20)
        }
        Button(action: dumpDevices) {
          Text("Dump Devices").foregroundColor(.white)
            .padding()
            .frame(width: 160, height: 50)
            .background(Color.blue)
            .cornerRadius(10.0).padding(.top, 20)
        }
        Button(action: resetKeychain) {
          Text("Reset Keychain").foregroundColor(.white)
            .padding()
            .frame(width: 160, height: 50)
            .background(Color.blue)
            .cornerRadius(10.0).padding(.top, 20)
        }
        Button(action: restartApplication) {
          Text("Restart App").foregroundColor(.white)
            .padding()
            .frame(width: 160, height: 50)
            .background(Color.blue)
            .cornerRadius(10.0).padding(.top, 20)
        }
      }
    }
  }
}

struct DevTools_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      DevTools(router: ViewRouter()).preferredColorScheme(.light)
      DevTools(router: ViewRouter()).environment(\.colorScheme, .dark)
    }
  }
}

extension UIDevice {
  static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
    }
  }
}

// A view modifier that detects shaking and calls a function of our choosing.
struct DeviceShakeViewModifier: ViewModifier {
  let action: () -> Void
  
  func body(content: Content) -> some View {
    content
      .onAppear()
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
        action()
      }
  }
}

// A View extension to make the modifier easier to use.
extension View {
  func onShake(perform action: @escaping () -> Void) -> some View {
    self.modifier(DeviceShakeViewModifier(action: action))
  }
}
