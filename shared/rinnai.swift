//
//  rinnai.swift
//  iOS
//
//  Created by Joey Eamigh on 4/20/22.
//

// based on https://github.com/explosivo22/rinnaicontrolr

import Foundation
import CoreData
import SwiftyJSON
import SwiftDate

final class Rinnai {
  private var username: String
  private var db = PersistenceController.i.container.viewContext
  private var demoMode = false
  init(username: String) {
    self.username = username.lowercased();
    if (self.username == "test@apple.com") { demoMode = true }
  }
  
  private func setShadow(_ device: Device, _ key: String, _ value: String) async throws -> Bool {
    print("Setting shadow key \(key) to value \(value)")
    var request = URLRequest(url: URL(string: "https://d1coipyopavzuf.cloudfront.net/api/device_shadow/input")!)
    request.httpMethod = "POST"
    request.addValue("okhttp/3.12.1", forHTTPHeaderField: "User-Agent")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    do {
      request.httpBody = "user=\(device.user!)&thing=\(device.thing!)&attribute=\(key)&value=\(value)".data(using: .utf8, allowLossyConversion: false)
      
      let (_, status) = try await URLSession.shared.data(for: request)
      //      print(try! JSON(data: data))
      //      print(status)
      
      guard let httpResponse = status as? HTTPURLResponse else {
        print("No valid response")
        return false
      }
      guard 200 ..< 300 ~= httpResponse.statusCode else {
        print("Status code was \(httpResponse.statusCode), but expected 2xx")
        return false
      }
      
      return true
    } catch {
      print("error: \(error)")
      return false
    }
  }
  
  func setRecirculation(_ device: Device, _ duration: Double) async throws -> Bool {
    if (demoMode) { return true }
    do {
      let _ = try await self.setShadow(device, "set_priority_status", "true")
      if (duration > 0.0) { let _ = try await self.setShadow(device, "recirculation_duration", String(Int(duration))) }
      return try await self.setShadow(device, "set_recirculation_enabled", duration == 0.0 ? "false" : "true")
    } catch {
      print("error: \(error)")
      return false
    }
  }
  
  func getDevices() async throws -> Bool {
    if (demoMode) { dummyData(); return true }
    print("fetching devices")
    var request = URLRequest(url: URL(string: "https://s34ox7kri5dsvdr43bfgp6qh6i.appsync-api.us-east-1.amazonaws.com/graphql")!)
    request.httpMethod = "POST"
    let str = deviceGraphQLString.replacingOccurrences(of: "{{ email }}", with: self.username)
    request.httpBody = str.data(using: .utf8, allowLossyConversion: false)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("aws-amplify/3.4.3 react-native", forHTTPHeaderField: "x-amz-user-agent")
    request.addValue("da2-dm2g4rqvjbaoxcpo4eccs3k5he", forHTTPHeaderField: "x-api-key")
    let session = URLSession.shared
    
    do {
      let (data, _) = try await session.data(for: request)
      let json = try JSON(data: data)
      //      print(json)
      print("fetched data")
      if (json["data"]["getUserByEmail"]["items"].count < 1) {
        return false
      }
      for (_, item) in json["data"]["getUserByEmail"]["items"] {
        for (_, device) in item["devices"]["items"] {
          var dev: Device
          
          let fetchRequest = Device.fetchRequest()
          fetchRequest.predicate = NSPredicate(format: "id == %@", device["id"].stringValue)
          let existing = try self.db.fetch(fetchRequest)
          
          if (!existing.isEmpty) {
            dev = existing.first!
          } else {
            dev = Device(context: self.db)
          }
          
          let schedules: [Schedule] = self.parseSchedules(device["schedule"]["items"])
          
          dev.lastUpdated = Date()
          dev.id = device["id"].stringValue
          dev.name = device["device_name"].stringValue
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
          dev.rinnaiLastUpdated = dateFormatter.date(from: device["shadow"]["updatedAt"].stringValue)
          dev.recirculating = device["shadow"]["recirculation_enabled"].boolValue
          dev.duration = Double(device["shadow"]["recirculation_duration"].stringValue)!
          dev.schedules = Set(schedules) as NSSet
          dev.timezone = String(device["shadow"]["timezone"].stringValue.prefix(3))
          dev.user = device["user_uuid"].stringValue
          dev.thing = device["thing_name"].stringValue
          
          try self.db.save()
          
          Widgeter.refresh()
          
          return true
        }}
    } catch {
      print("error: \(error)")
      return false
    }
    return false
  }
  
  private func parseSchedules(_ schedules: JSON) -> [Schedule] {
    do {
      var fS: [Schedule] = []
      
      for (_, schedule) in schedules {
        if (!schedule["active"].boolValue) { break }
        
        var s: Schedule
        
        let fetchRequest = Schedule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", schedule["id"].stringValue)
        let existing = try self.db.fetch(fetchRequest)
        
        if (!existing.isEmpty) {
          s = existing.first!
        } else {
          s = Schedule(context: self.db)
        }
        
        let timesString = schedule["times"].arrayValue.first?.stringValue
        let timeStrings = matches(for: "(?<==).*?(?=[,}])", in: timesString!)
        
        let startString = timeStrings.first
        let startToD = matches(for: "(am|pm)", in: startString!).first
        var startHour = Int16(matches(for: "([0-9]+)(?=:)", in: startString!).first!)!
        if (startToD == "pm") { startHour += 12 }
        
        let endString = timeStrings.last
        let endToD = matches(for: "(am|pm)", in: endString!).first
        var endHour = Int16(matches(for: "([0-9]+)(?=:)", in: endString!).first!)!
        if (endToD == "pm") { endHour += 12 }
        
        let daysString = schedule["days"].arrayValue.first?.stringValue
        let days = matches(for: "\\d", in: daysString!).joined(separator: ",")
        
        s.id = schedule["id"].stringValue
        s.startMinute = Int16(matches(for: "(?<=:)([0-9]+)", in: startString!).first!)!
        s.endMinute = Int16(matches(for: "(?<=:)([0-9]+)", in: endString!).first!)!
        s.startHour = startHour
        s.endHour = endHour
        s.name = schedule["name"].stringValue
        s.days = days
        
        fS.append(s)
      }
      
      //      print("fs: \(fS)")
      return fS
    } catch {
      print("error: \(error)")
      return []
    }
  }
  
  private func dummyData() {
    do {
      var dev: Device
      
      let fetchRequest = Device.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "id == %@", "1234")
      let existing = try self.db.fetch(fetchRequest)
      
      if (!existing.isEmpty) {
        dev = existing.first!
      } else {
        dev = Device(context: self.db)
      }
      
      dev.lastUpdated = Date()
      dev.id = "1234"
      dev.name = "Apple Water Heater"
      dev.rinnaiLastUpdated = Date()
      dev.recirculating = false
      dev.duration = 0.0
      dev.timezone = "EST"
      dev.user = "1234"
      dev.thing = "1234"
      
      try! self.db.save()
      Widgeter.refresh()
    } catch {
      print("error: \(error)")
    }
  }
  
  static func determineEndTime(_ device: Device) -> (scheduled: Bool, end: Date) {
    if (!device.recirculating) { return (false, Date()) }
    let rg = Region(calendar: Calendars.gregorian, zone: TimeZone(abbreviation: String((device.timezone ?? "EST").prefix(3)))!, locale: Locales.englishUnitedStates)
    let cMinute = DateInRegion(Date(), region: rg).minute
    let cHour = DateInRegion(Date(), region: rg).hour
    let dW = DateInRegion(Date(), region: rg).weekday
    
    for s in (device.schedules?.allObjects ?? []) as! [Schedule]  {
      if (cHour < s.startHour || cHour > s.endHour) { continue }
      if (cHour == s.endHour && cMinute > s.endMinute) { continue }
      if (!s.days!.contains(String(dW - 1))) { continue }

      let endDate = Calendar.current.date(bySettingHour: Int(s.endHour), minute: Int(s.endMinute), second: 0, of: Date())!
      return (true, endDate)
    }
    
    let endDate = device.rinnaiLastUpdated!.addingTimeInterval(device.duration * 60)
    return (false, endDate)
  }
  
  static func isDuringSchedule(_ device: Device) -> Bool {
    let rg = Region(calendar: Calendars.gregorian, zone: TimeZone(abbreviation: String((device.timezone ?? "EST").prefix(3)))!, locale: Locales.englishUnitedStates)
    let cMinute = DateInRegion(Date(), region: rg).minute
    let cHour = DateInRegion(Date(), region: rg).hour
    let dW = DateInRegion(Date(), region: rg).weekday
    
    for s in (device.schedules?.allObjects ?? []) as! [Schedule]  {
      if (cHour < s.startHour || cHour > s.endHour) { continue }
      if (cHour == s.endHour && cMinute > s.endMinute) { continue }
      if (!s.days!.contains(String(dW - 1))) { continue }

      return true
    }
  
    return false
  }
  
  static func startAndEndTimes(_ device: Device) -> [Date] {
    var dates: [Date] = []
    
    for s in (device.schedules?.allObjects ?? []) as! [Schedule]  {
      let start = Calendar.current.date(bySettingHour: Int(s.startHour), minute: Int(s.startMinute), second: 0, of: Date())!
      let end = Calendar.current.date(bySettingHour: Int(s.endHour), minute: Int(s.endMinute), second: 0, of: Date())!
      
      dates.append(start)
      dates.append(end)
    }
    
    return dates
  }
  
  static func endTimeText(_ endDate: (scheduled: Bool, end: Date)) -> String {
    return "\(endDate.end.in(region: .current).toFormat("h:mm a z"))"
  }
}

func matches(for regex: String, in text: String) -> [String] {
  do {
    let regex = try NSRegularExpression(pattern: regex)
    let results = regex.matches(in: text,
                                range: NSRange(text.startIndex..., in: text))
    return results.map {
      String(text[Range($0.range, in: text)!])
    }
  } catch let error {
    print("invalid regex: \(error.localizedDescription)")
    return []
  }
}

let deviceGraphQLString = "{\n    \"query\": \"query GetUserByEmail($email: String, $sortDirection: ModelSortDirection, $filter: ModelRinnaiUserFilterInput, $limit: Int, $nextToken: String) {\\n  getUserByEmail(email: $email, sortDirection: $sortDirection, filter: $filter, limit: $limit, nextToken: $nextToken) {\\n    items {devices {\\n        items {\\n          id\\n          thing_name\\n          device_name\\n          dealer_uuid\\n          city\\n          state\\n          street\\n          zip\\n          country\\n          firmware\\n          model\\n          dsn\\n          user_uuid\\n          connected_at\\n          key\\n          lat\\n          lng\\n          address\\n          vacation\\n          createdAt\\n          updatedAt\\n          activity {\\n            clientId\\n            serial_id\\n            timestamp\\n            eventType\\n          }\\n          shadow {\\n            heater_serial_number\\n            ayla_dsn\\n            rinnai_registered\\n            do_maintenance_retrieval\\n            model\\n            module_log_level\\n            set_priority_status\\n            set_recirculation_enable\\n            set_recirculation_enabled\\n            set_domestic_temperature\\n            set_operation_enabled\\n            schedule\\n            schedule_holiday\\n            schedule_enabled\\n            do_zigbee\\n            timezone\\n            timezone_encoded\\n            priority_status\\n            recirculation_enabled\\n            recirculation_duration\\n            lock_enabled\\n            operation_enabled\\n            module_firmware_version\\n            recirculation_not_configured\\n            maximum_domestic_temperature\\n            minimum_domestic_temperature\\n            createdAt\\n            updatedAt\\n          }\\n          monitoring {\\n            serial_id\\n            dealer_uuid\\n            user_uuid\\n            request_state\\n            createdAt\\n            updatedAt\\n            dealer {\\n              id\\n              name\\n              email\\n              admin\\n              approved\\n              confirmed\\n              aws_confirm\\n              imported\\n              country\\n              city\\n              state\\n              street\\n              zip\\n              company\\n              username\\n              firstname\\n              lastname\\n              st_accesstoken\\n              st_refreshtoken\\n              phone_country_code\\n              phone\\n              primary_contact\\n              terms_accepted\\n              terms_accepted_at\\n              terms_email_sent_at\\n              terms_token\\n              roles\\n              createdAt\\n              updatedAt\\n            }\\n          }\\n          schedule {\\n            items {\\n              id\\n              serial_id\\n              name\\n              schedule\\n              days\\n              times\\n              schedule_date\\n              active\\n              createdAt\\n              updatedAt\\n            }\\n            nextToken\\n          }\\n          info {\\n            serial_id\\n            ayla_dsn\\n            name\\n            domestic_combustion\\n            domestic_temperature\\n            wifi_ssid\\n            wifi_signal_strength\\n            wifi_channel_frequency\\n            local_ip\\n            public_ip\\n            ap_mac_addr\\n            recirculation_temperature\\n            recirculation_duration\\n            zigbee_inventory\\n            zigbee_status\\n            lime_scale_error\\n            mc__total_calories\\n            type\\n            unix_time\\n            m01_water_flow_rate_raw\\n            do_maintenance_retrieval\\n            aft_tml\\n            tot_cli\\n            unt_mmp\\n            aft_tmh\\n            bod_tmp\\n            m09_fan_current\\n            m02_outlet_temperature\\n            firmware_version\\n            bur_thm\\n            tot_clm\\n            exh_tmp\\n            m05_fan_frequency\\n            thermal_fuse_temperature\\n            m04_combustion_cycles\\n            hardware_version\\n            m11_heat_exchanger_outlet_temperature\\n            bur_tmp\\n            tot_wrl\\n            m12_bypass_servo_position\\n            m08_inlet_temperature\\n            m20_pump_cycles\\n            module_firmware_version\\n            error_code\\n            warning_code\\n            internal_temperature\\n            tot_wrm\\n            unknown_b\\n            rem_idn\\n            m07_water_flow_control_position\\n            operation_hours\\n            thermocouple\\n            tot_wrh\\n            recirculation_capable\\n            maintenance_list\\n            tot_clh\\n            temperature_table\\n            m19_pump_hours\\n            oem_host_version\\n            schedule_a_name\\n            zigbee_pairing_count\\n            schedule_c_name\\n            schedule_b_name\\n            model\\n            schedule_d_name\\n            total_bath_fill_volume\\n            dt\\n            createdAt\\n            updatedAt\\n          }\\n          errorLogs {\\n            items {\\n              id\\n              serial_id\\n              ayla_dsn\\n              name\\n              lime_scale_error\\n              m01_water_flow_rate_raw\\n              m02_outlet_temperature\\n              m04_combustion_cycles\\n              m08_inlet_temperature\\n              error_code\\n              warning_code\\n              operation_hours\\n              active\\n              createdAt\\n              updatedAt\\n            }\\n            nextToken\\n          }\\n          registration {\\n            items {\\n              serial\\n              dealer_id\\n              device_id\\n              user_uuid\\n              model\\n              gateway_dsn\\n              application_type\\n              recirculation_type\\n              install_datetime\\n              registration_type\\n              dealer_user_email\\n              active\\n              createdAt\\n              updatedAt\\n            }\\n            nextToken\\n          }\\n        }\\n        nextToken\\n      }\\n    }\\n    nextToken\\n  }\\n}\\n\",\n    \"variables\": {\n        \"email\": \"{{ email }}\"\n    }\n}"
