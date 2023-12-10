//
//  DriveWireSerialDriver.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import ORSSerial

/// Provides a serial interface to a DriveWire host.
///
/// This class provides the ability to connect to a guest on a serial port. Provide the
/// device name of the serial port in ``init(serialPort:)``, then start the
/// driver by calling ``run()``. When you're ready for the driver to stop, set ``quit`` to `true`.
class DriveWireSerialDriver : NSObject, DriveWireDelegate, ORSSerialPortDelegate {
    /// A flag that when set to `true`,  causes the driver to stop running.
    public var quit = false
    
    private var performDump = true
    private var port : ORSSerialPort?
    
    /// The host object.
    internal var host : DriveWireHost?

    @_documentation(visibility: private)
    internal func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
    }
    
    @_documentation(visibility: private)
    internal func serialPortWasOpened(_ serialPort: ORSSerialPort) {
    }
    
    @_documentation(visibility: private)
    internal func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print(error)
    }
    
    @_documentation(visibility: private)
    internal func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        var d = data
        if performDump == true {
            data.dump(prefix: "->")
        }
        host?.send(data: &d)
    }
    
    @_documentation(visibility: private)
    internal func transactionCompleted(opCode: UInt8) {
    }
    
    @_documentation(visibility: private)
    internal func dataAvailable(host: DriveWireHost, data: Data) {
        if performDump == true {
            data.dump(prefix: "<-")
        }
        port?.send(data)
    }
    
    /// Create a driver that connects to a serial port.
    ///
    /// - Parameters:
    ///     - serialPort: The name of the serial port device to connect to.
    convenience init(serialPort: String) {
        self.init(serialPort: serialPort, baudRate: 230400)
    }
    
    /// Create a driver that connects to a serial port with a specific baud rate.
    ///
    /// - Parameters:
    ///     - serialPort: The name of the serial port device to connect to.
    ///     - baudRate: The number of bits per second of the device.
    init(serialPort: String, baudRate: NSNumber) {
        super.init()
        host = DriveWireHost(delegate: self)
        port = ORSSerialPort(path: serialPort)
        if let port = port {
            port.delegate = self
            port.baudRate = baudRate
            port.open()
        }
    }
    
    /// Start the driver.
    ///
    /// This method returns when ``quit`` is `true`.
    public func run() {
        while self.quit == false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 10.0))
        }
    }
}

