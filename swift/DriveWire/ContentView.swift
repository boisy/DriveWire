//
//  ContentView.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import SwiftUI
import ORSSerial

 struct SerialPortSelector: View {
     @Binding var selectedPortName : String
     
     var body: some View {
         HStack {
             Picker("Serial port:", selection: $selectedPortName) {
                 ForEach(ObservableSerialPortManager().availablePorts, id: \.self) { port in
                     Text(port.name).tag(port.name)
                 }
             }
        }
    }
}

struct ContentView: View {
    @Binding var document: DriveWireDocument
    @State var selectedName : String = ObservableSerialPortManager().availablePorts[0].name
    @State var serialDriver = DriveWireSerialDriver()
    var body: some View {
        HStack{
            TextEditor(text: $document.text)
        }
        SerialPortSelector(selectedPortName: $selectedName).onChange(of: selectedName) { oldValue, newValue in
            serialDriver.portName = newValue
            serialDriver.baudRate = 230400
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
