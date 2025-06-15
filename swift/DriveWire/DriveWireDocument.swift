//
//  DriveWireSwiftDocument.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import SwiftUI
import UniformTypeIdentifiers
import ORSSerial
import AppIntents
extension UTType {
    static var exampleText: UTType {
        UTType(importedAs: "com.boisypitre.drivewire-document")
    }
}

final class DriveWireDocument: FileDocument {
    @Published var serialDriver = DriveWireSerialDriver()

    static var readableContentTypes: [UTType] { [.exampleText] }

    init() {
    }

    struct ReloadVirtualDriveIntent: AppIntent {
        static let title: LocalizedStringResource = "Reload virtual drives"
        static var description =
             IntentDescription("Instructs DriveWire to reload all virtual drives on all open documents.")
        @AppDependency private var hostProvider : DriveWireHost
        
        func perform() async throws -> some IntentResult {
          // reload
            
            hostProvider.reloadVirtualDrives()
          return .result()
        }
    }

    #if false
    struct AppShortcuts: AppShortcutsProvider {
        @AppShortcutsBuilder
        static var appShortcuts: [AppShortcut] {
            AppShortcut(
                intent: ReloadVirtualDriveIntent(),
                phrases: ["Reload virtual drives"],
                shortTitle: LocalizedStringResource("Reload"),
                systemImageName: "externaldrive"
            )
        }
    }
    #endif

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.serialDriver = try JSONDecoder().decode(DriveWireSerialDriver.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(serialDriver)
        return .init(regularFileWithContents: data)
    }
}
