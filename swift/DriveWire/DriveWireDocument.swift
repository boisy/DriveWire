//
//  DriveWireSwiftDocument.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import SwiftUI
import UniformTypeIdentifiers
import ORSSerial
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
