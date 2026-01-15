//
//  Extensions.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/14/26.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    static let metered = Color(hex: 0xD95F02)
    static let unmetered = Color(hex: 0x1B9E77)
}
