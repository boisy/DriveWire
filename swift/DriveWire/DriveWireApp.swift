//
//  DriveWireSwiftApp.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import SwiftUI

@main
struct DriveWireApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: DriveWireDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
