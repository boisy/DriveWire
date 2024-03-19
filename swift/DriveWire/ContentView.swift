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
    @State var selectedName = "NONE"
    @State var selectedBaud = "57600"
    @State var selectedDisk0 = ""
    @State var selectedDisk1 = ""
    @State var selectedDisk2 = ""
    @State var selectedDisk3 = ""
    
    var body: some View {
        let drives: [DriveSelector] = [
            DriveSelector(selectedDisk: $selectedDisk0),
            DriveSelector(selectedDisk: $selectedDisk1),
            DriveSelector(selectedDisk: $selectedDisk2),
            DriveSelector(selectedDisk: $selectedDisk3)
        ]
        
        drives[0]
            .onChange(of: selectedDisk0) { oldValue, newValue in
            do {
                try document.serialDriver.host?.insertVirtualDisk(driveNumber: 0, imagePath: newValue)
            } catch {
                
            }
            }.onAppear(perform: {
                guard let host = document.serialDriver.host else {
                    return
                }
                if host.virtualDrives.count > 0 {
                    let diskName = host.virtualDrives[0].imagePath
                    selectedDisk0 = diskName
                }
            })

        drives[1]
            .onChange(of: selectedDisk1) { oldValue, newValue in
            do {
                try document.serialDriver.host?.insertVirtualDisk(driveNumber: 1, imagePath: newValue)
            } catch {
            }
            }

        HStack{
            TextEditor(text: $document.serialDriver.log)
        }
        
        SerialPortSelector(selectedPortName: $selectedName, selectedBaudRate: $selectedBaud).onChange(of: selectedName) { oldValue, newValue in
            document.serialDriver.portName = newValue
        }.onChange(of: selectedBaud) { oldValue, newValue in
            document.serialDriver.baudRate = Int(newValue)!
        }.onDisappear(perform: {
            document.serialDriver.stop()
        }).onAppear(perform: {
            selectedName = document.serialDriver.portName
            selectedBaud = String(document.serialDriver.baudRate)
        })
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
