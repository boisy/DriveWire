//
//  ContentView.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import SwiftUI
import ORSSerial

/*
 struct SerialPortSelector: View {
    @ObservedObject var serialPortManager = ObservableSerialPortManager()
    @State var portName = ""
    @State var testName = ""
    var body: some View {
        Picker("Serial port:", selection: $portName, content: {
            ForEach(serialPortManager.availablePorts, id: \.self) { port in
                Text(port.description)
            }
        })
//        List(serialPortManager.availablePorts, id: \.path) { port in
//            Text(port.name)
//        }
    }
}
 */
struct ContentView: View {
    @Binding var document: DriveWireDocument
    @State var portName : String = ""
    let serialDriver = DriveWireSerialDriver(serialPort: "/dev/cu.usbserial-FT079LCR3")
    
    var body: some View {
        HStack{
            TextEditor(text: $document.text)
        }
    }
    func my() {
        print(portName)
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
        availablePorts = portManager.availablePorts as? [ORSSerialPort] ?? []
    }
}

/*
 #Preview {
    ContentView(document: .constant(DriveWireDocument()))
}
*/
