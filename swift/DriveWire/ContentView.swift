//
//  ContentView.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import SwiftUI
import ORSSerial

struct DriveSelector: View {
    let buttonSize = 80.0
    @Binding var selectedDisk : String
    var body: some View {
        HStack {
            Button(action: {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK {
                    self.selectedDisk = panel.url?.relativePath ?? "<none>"
                }
            }) {
                Image(systemName: "externaldrive")
            }.frame(width: buttonSize, height: buttonSize)
                .font(.system(size: buttonSize * 0.7))
                .foregroundColor(Color.white)
                .background(Color.blue)
                .cornerRadius(buttonSize / 6.0)
                .buttonStyle(PlainButtonStyle())
            VStack {
                TextField("Disk Image", text: $selectedDisk)
            }
        }
    }
}

struct SerialPortSelector: View {
     @Binding var selectedPortName : String
     @Binding var selectedBaudRate : String
     
     var body: some View {
         HStack {
             Picker("Serial port:", selection: $selectedPortName) {
                 Text("No device").tag("NONE")
                 ForEach(ObservableSerialPortManager().availablePorts, id: \.self) { port in
                     Text(port.name).tag(port.name)
                 }
             }
             Picker("Baud rate:", selection: $selectedBaudRate) {
                 ForEach(["57600", "115200", "230400"], id: \.self) { baud in
                     Text(baud).tag(baud)
                 }
             }
        }
    }
}

struct ContentView: View {
    @Binding var document: DriveWireDocument
    @State var selectedName : String = "NONE"
    @State var selectedBaud = "57600"
    @State var selectedDisk = ""
    var serialDriver = DriveWireSerialDriver()
    
    var body: some View {
        let drives: [DriveSelector] = [
            DriveSelector(selectedDisk: $selectedDisk),
            DriveSelector(selectedDisk: $selectedDisk),
            DriveSelector(selectedDisk: $selectedDisk),
            DriveSelector(selectedDisk: $selectedDisk)
        ]
        
        drives[0]
            .onChange(of: selectedDisk) { oldValue, newValue in
            do {
                try serialDriver.host?.insertVirtualDisk(driveNumber: 0, imagePath: newValue)
            } catch {
                
            }
        }
        DriveSelector(selectedDisk: $selectedDisk).onChange(of: selectedDisk) { oldValue, newValue in
            do {
                try serialDriver.host?.insertVirtualDisk(driveNumber: 0, imagePath: newValue)
            } catch {
                
            }
        }
        HStack{
            TextEditor(text: $document.text)
        }
        SerialPortSelector(selectedPortName: $selectedName, selectedBaudRate: $selectedBaud).onChange(of: selectedName) { oldValue, newValue in
            serialDriver.portName = newValue
        }.onChange(of: selectedBaud) { oldValue, newValue in
            serialDriver.baudRate = NSNumber(value: Int(newValue)!)
        }
    }
}

class ObservableSerialPortManager: ObservableObject {
    @Published var availablePorts: [ORSSerialPort] = []
    private var portManager: ORSSerialPortManager

    init() {
        portManager = ORSSerialPortManager.shared()
        
        NotificationCenter.default.addObserver(self, selector: #selector(portsWereConnected(_:)), name: Notification.Name.ORSSerialPortsWereConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(portsWereDisconnected(_:)), name: Notification.Name.ORSSerialPortsWereDisconnected, object: nil)

        updateAvailablePorts()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func portsWereConnected(_ notification: Notification) {
        updateAvailablePorts()
    }

    @objc private func portsWereDisconnected(_ notification: Notification) {
        updateAvailablePorts()
    }

    private func updateAvailablePorts() {
        availablePorts = portManager.availablePorts as [ORSSerialPort]
    }
}

/*
 #Preview {
    ContentView(document: .constant(DriveWireDocument()))
}
*/
