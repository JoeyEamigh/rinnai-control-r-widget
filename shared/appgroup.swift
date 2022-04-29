//
//  appgroup.swift
//  rinnai-control-r-widget
//
//  Created by Joey Eamigh on 4/27/22.
//

import Foundation

public enum AppGroup: String {
  case facts = "group.com.joeyeamigh.rinnai-control-r-widget"
  
  public var containerURL: URL {
    switch self {
    case .facts:
      return FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: self.rawValue)!
    }
  }
}
