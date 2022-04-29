//
//  local-notifications.swift
//  iOS
//
//  Created by Joey Eamigh on 4/21/22.
//

import Foundation
import SwiftUI
class LocalNotificationManager: ObservableObject {
  var notifications = [Notification]()
  
  init() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if granted == true && error == nil {
        print("Notifications permitted")
      } else {
        print("Notifications not permitted")
      }
    }
  }
  
  func sendNotification(title: String, subtitle: String?, body: String, launchIn: Double) {
    let content = UNMutableNotificationContent()
    content.title = title
    if let subtitle = subtitle {
      content.subtitle = subtitle
    }
    content.body = body
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: launchIn, repeats: false)
    let request = UNNotificationRequest(identifier: "rC-r notif", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }
}
