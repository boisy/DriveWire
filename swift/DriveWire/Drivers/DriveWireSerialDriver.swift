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
class DriveWireSerialDriver : NSObject, DriveWireDelegate, ORSSerialPortDelegate, ObservableObject {
    /// A flag that when set to `true`,  causes the driver to stop running.
    public var quit = false
    
    /// A flag that when set to `true`,  causes serial traffic to log.
    public var logging = false
         
    private var serialPort : ORSSerialPort?
    
    /// The serial port associated with this driver.
    public var portName : String {
        get {
            return serialPort!.name
        }
        set(newPortName) {
            if let sp = serialPort {
                self.stop()
                sp.close()
            }
            
            if let serialPort = ORSSerialPort(path: "/dev/cu." + newPortName) {
                self.serialPort = serialPort
                serialPort.delegate = self
                serialPort.open()
                self.run()
            }
        }
    }
    
    /// The serial port's speed.'
    public var baudRate : NSNumber {
        get {
            return serialPort!.baudRate
        }
        set(newBaudRate) {
            serialPort?.baudRate = newBaudRate
        }
    }
    
    private var thread : Thread?
    
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
        if logging == true {
            data.dump(prefix: "->")
        }
        host?.send(data: &d)
    }
    
    @_documentation(visibility: private)
    internal func transactionCompleted(opCode: UInt8) {
    }
    
    @_documentation(visibility: private)
    internal func dataAvailable(host: DriveWireHost, data: Data) {
        if logging == true {
            data.dump(prefix: "<-")
        }
        serialPort?.send(data)
    }
    
    override init() {
        super.init()
        host = DriveWireHost(delegate: self)
    }
    
    /// Create a driver that connects to a serial port.
    ///
    /// - Parameters:
    ///     - serialPort: The name of the serial port device to connect to.
    convenience init(serialPort: String) {
        self.init(portName: serialPort, baudRate: 230400)
    }
    
    /// Create a driver that connects to a serial port with a specific baud rate.
    ///
    /// - Parameters:
    ///     - serialPort: The name of the serial port device to connect to.
    ///     - baudRate: The number of bits per second of the device.
    init(portName: String, baudRate: NSNumber) {
        super.init()
        host = DriveWireHost(delegate: self)
        self.serialPort = ORSSerialPort(path: portName)
        self.portName = portName
    }
    
    /// Start the driver.
    ///
    /// This method returns when ``quit`` is `true`.
    public func run() {
        thread = Thread(block: {
            while self.thread?.isCancelled == false {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
            }
        })
        thread?.start()
    }
    
    public func stop() {
        thread?.cancel()
    }
}

