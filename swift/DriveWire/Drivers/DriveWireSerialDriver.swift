//
//  DriveWireSerialDriver.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import ORSSerial

class DriveWireSerialDriver : NSObject, DriveWireDelegate, ORSSerialPortDelegate {
    var performDump = false
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
    
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print(error)
    }
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        var d = data
        if performDump == true {
            data.dump(prefix: "->")
        }
        host?.send(data: &d)
    }
    
    var quit = false
    var port : ORSSerialPort?
    
    func transactionCompleted(opCode: UInt8) {
    }
    
    func dataAvailable(host: DriveWireHost, data: Data) {
        if performDump == true {
            data.dump(prefix: "<-")
        }
        port?.send(data)
    }
    
    // The DriveWire model.
    var host : DriveWireHost?
    
    init(serialPort: String) {
        super.init()
        host = DriveWireHost(delegate: self)
        port = ORSSerialPort(path: serialPort)
        if let port = port {
            port.delegate = self
            port.baudRate = 230400
            port.open()
        }
    }
    
    func run() {
        while self.quit == false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 10.0))
        }
    }
}

