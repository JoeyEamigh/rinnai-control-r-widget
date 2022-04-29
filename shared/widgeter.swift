//
//  widgeter.swift
//  rinnai-control-r-widget
//
//  Created by Joey Eamigh on 4/27/22.
//

import Foundation
import WidgetKit

struct Widgeter {
  static func refresh() {
    WidgetCenter.shared.reloadTimelines(ofKind: "com.joeyeamigh.rinnai-control-r-widget.recirculating")
  }
}
