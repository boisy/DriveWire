//
//  LED.swift
//  DriveWire
//
//  Created by Boisy Pitre on 3/23/24.
//

import SwiftUI

struct LEDView : View {
    var body : some View {
        Circle()
        .strokeBorder(Color.blue,lineWidth: 4)
        .background(Circle().foregroundColor(Color.red))
    }
}
