//
//  DriveWireHost.swift
//  DriveWireSwift
//
//  Created by Boisy Pitre on 9/29/23.
//

import Foundation

/// An interface for receiving information from the DriveWire host.
protocol DriveWireDelegate {
    /// Informs the delegate that there is available data.
    ///
    /// - Parameters:
    ///     - host: The DriveWire host object.
    ///     - data: The data available for the delegate.
    func dataAvailable(host : DriveWireHost, data : Data)
    
    /// Informs the delegate that a DriveWire transaction completed.
    func transactionCompleted(opCode : UInt8)
}

/// Statistical information about the host.
public struct DriveWireStatistics {
    var lastOpCode : UInt8 = 0
    var lastDriveNumber : UInt8 = 0
    var lastLSN : Int = 0
    var readCount : Int = 0
    var writeCount : Int = 0
    var reReadCount : Int = 0
    var reWriteCount : Int = 0
    var lastGetStat : UInt8 = 0
    var lastSetStat : UInt8 = 0
    var lastCheckSum : UInt16 = 0
    var lastError : UInt8 = 0
}

/// Errors that the DriveWire host throws.
public enum DriveWireError : Error {
    /// There is already a virtual drive.
    case driveAlreadyExists
}

/// Manages communication with a DriveWire guest.
///
/// DriveWire defines a standard that provides device services to a *guest* that are located on a *host*. Connectivity occurs over a physical connection such as a serial cable. This gives the guest the appearance that these devices are local, when they are actually virtual. The DriveWire host provides virtual disk drive, virtual printer, and virtual serial port services.
///
/// The essence of communication between the guest and host is a documented set of uni- and bi-directional messages called transactions. Each transaction is composed of one or more packets, which are passed between the guest and host through a serial line connection.
///
public class DriveWireHost {
    /// Statistical information about the host.
    public var statistics = DriveWireStatistics()
    private var serialBuffer = Data()
    private var delegate : DriveWireDelegate?
    /// The DriveWire operation code of the operation that the host is currently executing.
    ///
    /// Inspect this property to determine what the operation the host is currently executing.
    public var currentOperation : UInt8 = 0
    /// An array of virtual drive tuples.
    ///
    /// The tuple holds the virtual drive number and the file path to each virtual disk that the host accesses.
    public var virtualDrives : [VirtualDrive] = []
    
    /// The guest's capability byte sent from ``OPDWINIT``.
    private var guestCapabilityByte : UInt8 = 0x00
    
    private struct DWOp {
        var opcode : UInt8 = 0
        var processor : ((Data) -> Int)
    }
    
    private var dwOperation : Array<DWOp> = []
    private var validateWithCRC = false
    private var fastwriteChannel : UInt8 = 0
    private var processor : ((Data) -> Int)?
    
    /// The no-operation operation code.
    ///
    /// This operation does nothing.
    public let OPNOP : UInt8 = 0x00
    /// The time operation code.
    ///
    /// This is a bi-directional transaction that requests the date and time from the host. The format of the response is a 6-byte packet.
    ///
    /// | Byte | Value | Range | Notes |
    /// | ------- | ------- | ------- | ------- |
    /// | 0 | Year | 0-255 | Represents years 1900 to 2155. |
    /// | 1 | Month | 1-12 | Represents January to December. |
    /// | 2 | Day | 1-31 | Represents the day of the month. |
    /// | 3 | Hour | 0-23 | Represents the hour. |
    /// | 4 | Minute | 0-59 | Represents the minute. |
    /// | 5 | Second | 0-59 | Represents the second. |
    public let OPTIME : UInt8 = 0x23
    /// The named object mount operation code.
    public let OPNAMEOBJMOUNT : UInt8 = 0x01
    /// The named object mount operation code.
    public let OPNAMEOBJCREATE : UInt8 = 0x02
    /// The initialization operation code.
    ///
    /// This is a bi-directional transaction that informs the host of its driver version or capabilities. The host responds with it's own version and capabilities.
    /// The exact meanings of the version byte are not yet defined. The OS-9 driver currently uses this operation to determine whether it should load DriveWire 4-specific extensions
    /// such as the virtual channel polling routine.
    ///
    /// The guest initiates the transaction with this 2-byte packet.
    ///
    /// | Offset | Value |
    /// | ------- | ------- |
    /// | 0 | The operation code ($5A). |
    /// | 1 | The guest's version/capabilities byte. |
    ///
    /// The host responds with its own version/capabilities byte.
    ///
    /// | Offset | Value |
    /// | ------- | ------- |
    /// | 0 | The host version/capabilities byte. |
    public let OPDWINIT : UInt8 = 0x5A
    /// The read operation code.
    ///
    /// This operation provides 256-byte sectors of binary data to the guest from a virtual disk. The guest provides a virtual drive number from 0 - 255 and a 24-bit logical sector number (LSN) that represents the offset from the beginning of the virtual disk to the desired sector.
    ///
    /// The guest initiates the transaction with this 5-byte packet.
    ///
    /// | Offset | Value |
    /// | ------- | ------- |
    /// | 0 | The operation code ($52). |
    /// | 1 | The virtual drive number from 0 - 255. |
    /// | 2 | Bits 23-16 of the 24 bit logical sector number |
    /// | 3 | Bits 15-8 of the 24 bit logical sector number |
    /// | 4 | Bits 7-0 of the 24 bit logical sector number |
    ///
    /// If the operation is successful, the host responds with the following packet,
    ///
    /// | Offset | Value |
    /// | ------- | ------- |
    /// | 0 | A value of $00 indicating the transaction was successful. |
    /// | 1 | Bits 15-8 of the checksum of the 256-byte sector. |
    /// | 2 | Bits 7-0 of the checksum of the 256-byte sector. |
    /// | 3 - 258 | The 256-byte sector data. |
    ///
    /// If the operation is not successful, the host responds with the following packet.
    ///
    /// | Offset | Value |
    /// | ------- | ------- |
    /// | 0 | The error code greater than zero indicating the transaction failed. |
    ///
    /// If the guest receives an error code that isn't zero, it may choose to retry the operation using ``OPREREAD``.
    public let OPREAD : UInt8 = 0x52
    /// The read extended operation code.
    ///
    /// This is an extended version of the ``OPREAD``.
    public let OPREADEX : UInt8 = 0xD2
    /// The initialization operation code.
    ///
    /// This is a uni-directional transaction that indicates the guest is ready to use DriveWire. It doesn't cause any action on the host.
    /// Use ``OPDWINIT`` instead.
    @available(*, deprecated, message: "This is a historical operation code that you should no longer use.")
    public let OPINIT : UInt8 = 0x49
    /// The termination operation code.
    ///
    /// This is a uni-directional transaction that the guest can initiate to indicate it's ready to stop using DriveWire. It doesn't cause any action on the host.
    @available(*, deprecated, message: "This is a historical operation code that you should no longer use.")
    public let OPTERM : UInt8 = 0x54
    /// The re-read operation code.
    public let OPREREAD : UInt8 = 0x72
    /// The extended re-read operation code.
    public let OPREREADEX : UInt8 = 0xF2
    /// The write operation code.
    public let OPWRITE : UInt8 = 0x57
    /// The re-write operation code.
    public let OPREWRITE : UInt8 = 0x77
    /// The virtual drive  get status operation code.
    public let OPGETSTAT : UInt8 = 0x47
    /// The virtual drive set status operation code.
    public let OPSETSTAT : UInt8 = 0x53
    /// The reset operation code.
    ///
    /// This is a uni-directional transaction that the guest sends to the host to indicate that it completed a reset condition.
    @available(*, deprecated, message: "This is a historical operation code that you should no longer use.")
    public let OPRESET3 : UInt8 = 0xF8
    /// The reset operation code.
    ///
    /// This is a uni-directional transaction that the guest sends to the host to indicate that it completed a reset condition.
    @available(*, deprecated, message: "This is a historical operation code that you should no longer use.")
    public let OPRESET2 : UInt8 = 0xFE
    /// The reset operation code.
    ///
    /// This is a uni-directional transaction that the guest sends to the host to indicate that it completed a reset condition.
    public let OPRESET : UInt8 = 0xFE
    /// The WireBug operation code.
    public let OPWIREBUG : UInt8 = 0x42
    /// The print flush operation code.
    ///
    /// This is a uni-directional transaction that the guest sends to the host to indicate that the print buffer is ready for printing.
    ///
    /// Upon receipt, the host sends the contents of the print buffer to the configured printer, then it clears the print buffer.
    public let OPPRINTFLUSH : UInt8 = 0x46
    /// The print operation code.
    ///
    /// This is a uni-directional transaction that the guest sends to the host to add a byte of data to the print queue.
    ///
    /// The guest initiates the transaction with this 2-byte packet.
    ///
    /// | Offset | Value |
    /// | ------- | ------- |
    /// | 0 | The operation code ($5A). |
    /// | 1 | The byte of data to add to the queue. |
    ///
    /// Upon receiving this packet, the host adds the passed byte to its internal print buffer. To start the print operation, see ``OPPRINTFLUSH``.
    public let OPPRINT : UInt8 = 0x50
    /// The serial initialization operation code.
    public let OPSERINIT : UInt8 = 0x45
    /// The serial termination operation code.
    public let OPSERTERM : UInt8 = 0xC5
    /// The serial get status operation code.
    public let OPSERGETSTAT : UInt8 = 0x44
    /// The serial set status operation code.
    public let OPSERSETSTAT : UInt8 = 0xC4
    /// The serial read operation code.
    public let OPSERREAD : UInt8 = 0x43
    /// The serial read multiple operation code.
    public let OPSERREADM : UInt8 = 0x63
    /// The serial write operation code.
    public let OPSERWRITE : UInt8 = 0xC3
    /// The serial write multiple operation code.
    public let OPSERWRITEM : UInt8 = 0x64
    
    enum DWWirebugOpCode : UInt8 {
        case OP_WIREBUG_READREGS = 82
        case OP_WIREBUG_WRITEREGS = 114
        case OP_WIREBUG_READMEM = 77
        case OP_WIREBUG_WRITEMEM = 109
        case OP_WIREBUG_GO = 71
        
    }
    
    /// Creates a DriveWire host.
    ///
    /// - Parameters:
    ///     - delegate: The delegate that receives messages.
    init(delegate : DriveWireDelegate) {
        self.delegate = delegate
        
        dwOperation.append(DWOp(opcode:OPDWINIT, processor: self.OP_DWINIT))
        dwOperation.append(DWOp(opcode:OPNAMEOBJMOUNT, processor: self.OP_NAMEOBJ_MOUNT))
        dwOperation.append(DWOp(opcode:OPNAMEOBJCREATE, processor: self.OP_NAMEOBJ_CREATE))
        dwOperation.append(DWOp(opcode:OPNOP, processor: self.OP_NOP))
        dwOperation.append(DWOp(opcode:OPTIME, processor: self.OP_TIME))
        dwOperation.append(DWOp(opcode:OPINIT, processor: self.OP_INIT))
        dwOperation.append(DWOp(opcode:OPTERM, processor: self.OP_TERM))
        dwOperation.append(DWOp(opcode:OPREAD, processor: self.OP_READ))
        dwOperation.append(DWOp(opcode:OPREADEX, processor: self.OP_READEX))
        dwOperation.append(DWOp(opcode:OPREREAD, processor: self.OP_REREAD))
        dwOperation.append(DWOp(opcode:OPREREADEX, processor: self.OP_REREADEX))
        dwOperation.append(DWOp(opcode:OPWRITE, processor: self.OP_WRITE))
        dwOperation.append(DWOp(opcode:OPREWRITE, processor: self.OP_REWRITE))
        dwOperation.append(DWOp(opcode:OPGETSTAT, processor: self.OP_GETSTAT))
        dwOperation.append(DWOp(opcode:OPSETSTAT, processor: self.OP_SETSTAT))
        dwOperation.append(DWOp(opcode:OPRESET3, processor: self.OP_RESET))
        dwOperation.append(DWOp(opcode:OPRESET2, processor: self.OP_RESET))
        dwOperation.append(DWOp(opcode:OPRESET, processor: self.OP_RESET))
        dwOperation.append(DWOp(opcode:OPWIREBUG, processor: self.OP_WIREBUG))
        dwOperation.append(DWOp(opcode:OPPRINTFLUSH, processor: self.OP_PRINTFLUSH))
        dwOperation.append(DWOp(opcode:OPPRINT, processor: self.OP_PRINT))
        dwOperation.append(DWOp(opcode:OPSERINIT, processor: self.OP_SERINIT))
        dwOperation.append(DWOp(opcode:OPSERTERM, processor: self.OP_SERTERM))
        dwOperation.append(DWOp(opcode:OPSERGETSTAT, processor: self.OP_SERGETSTAT))
        dwOperation.append(DWOp(opcode:OPSERSETSTAT, processor: self.OP_SERSETSTAT))
        dwOperation.append(DWOp(opcode:OPSERREAD, processor: self.OP_SERREAD))
        dwOperation.append(DWOp(opcode:OPSERREADM, processor: self.OP_SERREADM))
        dwOperation.append(DWOp(opcode:OPSERWRITE, processor: self.OP_SERWRITE))
        dwOperation.append(DWOp(opcode:OPSERWRITEM, processor: self.OP_SERWRITEM))
        processor = OP_OPCODE
    }
    
    /// Inserts a virtual disk into the virtual drive.
    ///
     /// - Parameters:
    ///     - driveNumber: The drive number to insert the virtual disk into.
    ///     - imagePath: The page the virtual disk image to insert.
    public func insertVirtualDisk(driveNumber : Int, imagePath : String) throws {
        if let _ = virtualDrives.first(where: { $0.driveNumber == driveNumber }) {
            // A drive with this number already exists... disallow it.
            throw DriveWireError.driveAlreadyExists
        }

        virtualDrives.append(try VirtualDrive(driveNumber: driveNumber, imagePath: imagePath))
    }
    
    /// Ejects a virtual disk from the virtual drive.
    /// - Parameters:
    ///     - driveNumber: The drive number to remove the virtual disk image from.ds
    public func ejectVirtualDisk(driveNumber : Int) {
        virtualDrives.removeAll { $0.driveNumber == driveNumber }
    }
    
    /// Provides data to the DriveWire host.
    ///
    /// Call this function with the data you want to send to the host.
    ///
    /// - Parameters:
    ///     - data: Data to providen to the host.
    public func send(data : inout Data) {
        var bytesConsumed = 0
        
        serialBuffer.append(data)
        
        repeat
        {
            bytesConsumed = self.processor!(serialBuffer)
            
            if bytesConsumed > 0 {
                // chop off consumed bytes
                serialBuffer.replaceSubrange(0..<bytesConsumed, with: Data([]))
            }
        } while bytesConsumed > 0 && serialBuffer.count > 0
    }
    
    private var watchdog : Timer?
    
    private func setupWatchdog() {
        invalidateWatchdog()
        watchdog = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { time in
            self.resetState()
        })
    }
    
    private func invalidateWatchdog() {
        watchdog?.invalidate()
    }
    
    /// Computes a simple checksum of the passed data.
    ///
    /// - Parameters:
    ///     - data: The data payload to compute the checksum over.
    ///
    ///  - Returns: A 16-bit checksum value.
    public func compute16BitChecksum(data : Data) -> UInt16
    {
        var lastChecksum : UInt16 = 0x0000
        for d in data {
            lastChecksum += UInt16(d)
        }
        return lastChecksum;
    }
    
    private func resetState() {
        processor = OP_OPCODE
        invalidateWatchdog()
    }
    
    private func OP_DWINIT(data : Data) -> Int {
        var result = 0
        let expectedCount = 2
        currentOperation = OPDWINIT
        
        if data.count >= expectedCount {
            // Save capabilities byte.
            guestCapabilityByte = data[1]
            
            // Send the host capabilities byte.
            delegate?.dataAvailable(host: self, data: Data([0x00]))
            result = expectedCount
            
            // Reset the state machine.
            resetState()
        }
        
        return result
    }
    
    private func OP_NAMEOBJ_MOUNT(data : Data) -> Int {
        var result = 0
        let expectedCount = 259
        currentOperation = OPNAMEOBJMOUNT
        if data.count >= expectedCount {
            resetState()
            result = expectedCount;
            
            statistics.lastDriveNumber = data[1]
            delegate?.transactionCompleted(opCode: currentOperation)
        }
        
        return result
    }
    
    private func OP_NAMEOBJ_CREATE(data : Data) -> Int {
        var result = 0
        let expectedCount = 259
        currentOperation = OPNAMEOBJCREATE
        if data.count >= expectedCount {
            resetState()
            result = expectedCount;
            
            statistics.lastDriveNumber = data[1]
            delegate?.transactionCompleted(opCode: currentOperation)
        }
        
        return result
    }
    
    private func OP_NOP(data : Data) -> Int {
        currentOperation = OPNOP
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_TIME(data : Data) -> Int {
        currentOperation = OPTIME
        let currentDate = Date()
        let calendar = Calendar.current
        let year = UInt8(calendar.component(.year, from: currentDate) - 1900)
        let month = UInt8(calendar.component(.month, from: currentDate))
        let day = UInt8(calendar.component(.day, from: currentDate))
        let hour = UInt8(calendar.component(.hour, from: currentDate))
        let minute = UInt8(calendar.component(.minute, from: currentDate))
        let second = UInt8(calendar.component(.second, from: currentDate))
        resetState()
        delegate?.dataAvailable(host: self, data: Data([year, month, day, hour, minute, second]))
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_INIT(data : Data) -> Int {
        currentOperation = OPINIT
        resetState()
        statistics = DriveWireStatistics()  // reset statistics
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_TERM(data : Data) -> Int {
        currentOperation = OPTERM
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    // TODO: Complete
    private func OP_WRITE_CORE(data : Data, operation: UInt8) -> Int {
        var result = 0
        var error = 0
        let expectedCount = 263
        currentOperation = OPWRITE
        
        if data.count >= expectedCount {
            resetState()
            result = expectedCount;
            
            let driveNumber = data[1]
            let vLSN = Int(data[2]) << 16 + Int(data[3]) << 8 + Int(data[4])
            let sectorBuffer = data[5..<261]
            let checksum = Int(data[261])*256+Int(data[262])
            
            result = expectedCount;
            
            // Check if the drive number exists in our virtual drive list.
            if let virtualDrive = virtualDrives.first(where: { $0.driveNumber == driveNumber }) {
                // It exists! Read sector from disk image.
                statistics.lastDriveNumber = driveNumber
                statistics.readCount = statistics.readCount + 1
                error = virtualDrive.writeSector(lsn: vLSN, sector: sectorBuffer)
            } else {
                // It doesn't exist. Set the error code.
                error = 240;
            }
            
            statistics.lastDriveNumber = driveNumber
            delegate?.dataAvailable(host: self, data: Data([UInt8(error)]))
            delegate?.transactionCompleted(opCode: currentOperation)
        }
        
        return result
    }
    
    private func OP_WRITE(data : Data) -> Int {
        return OP_WRITE_CORE(data: data, operation: OPWRITE)
    }
    
    private func OP_REWRITE(data : Data) -> Int {
        return OP_WRITE_CORE(data: data, operation: OPREWRITE)
    }
    
    private func OP_GETSTAT(data : Data) -> Int {
        var result = 0
        let expectedCount = 3
        currentOperation = OPGETSTAT
        
        if data.count >= expectedCount {
            resetState()
            result = expectedCount;
            
            statistics.lastDriveNumber = data[1]
            statistics.lastGetStat = data[2]
            delegate?.transactionCompleted(opCode: currentOperation)
        }
        
        return result
    }
    
    private func OP_SETSTAT(data : Data) -> Int {
        var result = 0
        let expectedCount = 3
        currentOperation = OPSETSTAT
        
        if data.count >= expectedCount {
            resetState()
            result = expectedCount;
            
            statistics.lastDriveNumber = data[1]
            statistics.lastSetStat = data[2]
            delegate?.transactionCompleted(opCode: currentOperation)
        }
        
        return result
    }
    
    private func OP_RESET(data : Data) -> Int {
        currentOperation = OPRESET
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_WIREBUG(data : Data) -> Int {
        var result = 0
        let expectedCount = 24
        currentOperation = OPWIREBUG
        
        if data.count >= expectedCount {
            resetState()
            result = expectedCount;
            delegate?.transactionCompleted(opCode: currentOperation)
        }
        
        return result
    }
    
    /// The print buffer.
    private var printBuffer = Data()
    
    private func OP_PRINT(data : Data) -> Int {
        var result = 0
        let expectedCount = 2
        currentOperation = OPPRINT
        
        if data.count >= expectedCount {
            resetState()
            result = expectedCount
            let printerByte = data[1]
            printBuffer.append(printerByte)
            delegate?.transactionCompleted(opCode: currentOperation)
        }
        
        return result
    }
    
    private func OP_PRINTFLUSH(data : Data) -> Int {
        currentOperation = OPPRINTFLUSH
        resetState()
        
        // For now, just clear the print buffer
        printBuffer.removeAll()
        delegate?.transactionCompleted(opCode: currentOperation)
        
        return 1
    }
    
    private func OP_SERINIT(data : Data) -> Int {
        currentOperation = OPSERINIT
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_SERTERM(data : Data) -> Int {
        currentOperation = OPSERTERM
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_SERREAD(data : Data) -> Int {
        currentOperation = OPSERREAD
        resetState()
        delegate?.dataAvailable(host: self, data: Data([0x00, 0x00]))
        return 1
    }
    
    private func OP_SERREADM(data : Data) -> Int {
        currentOperation = OPSERREADM
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_SERWRITE(data : Data) -> Int {
        currentOperation = OPSERWRITE
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_SERWRITEM(data : Data) -> Int {
        currentOperation = OPSERWRITEM
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_SERGETSTAT(data : Data) -> Int {
        currentOperation = OPSERGETSTAT
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_SERSETSTAT(data : Data) -> Int {
        currentOperation = OPSERSETSTAT
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_FASTWRITE_Serial(data : Data) -> Int {
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_FASTWRITE_Screen(data : Data) -> Int {
        resetState()
        delegate?.transactionCompleted(opCode: currentOperation)
        return 1
    }
    
    private func OP_OPCODE(data: Data) -> Int {
        var result = 0
        
        setupWatchdog()
        
        let byte = data[0]
        
        if byte >= 0x80 && byte <= 0x8E {
            // FASTWRITE serial
            fastwriteChannel = byte & 0x0F;
            result = OP_FASTWRITE_Serial(data: data)
        }
        else if byte >= 0x91 && byte <= 0x9E {
            // FASTWRITE virtual screen
            self.fastwriteChannel = (byte & 0x0F) - 1;
            result = OP_FASTWRITE_Screen(data: data)
        } else {
            for e in dwOperation {
                if e.opcode == byte {
                    processor = e.processor
                    result = processor!(data)
                    break
                }
            }
        }
        
        return result;
    }
}

extension DriveWireHost {
    private func OP_REREADEX(data : Data) -> Int {
        return OP_READEX(data: data)
    }
    
    private func OP_READEX(data : Data) -> Int {
        currentOperation = OPREADEX
        var result = 0
        var error = 0
        var sectorBuffer = Data(repeating: 0, count: 256)
        var readexChecksum : UInt16 = 0
        
        if data.count >= 5 {
            let driveNumber = data[1]
            let vLSN = Int(data[2]) << 16 + Int(data[3]) << 8 + Int(data[4])
            
            // We read 5 bytes into this buffer (OP_READEX, 1 byte drive number, 3 byte LSN)
            result = 5;
            
            // Check if the drive number exists in our virtual drive list.
            if let virtualDrive = virtualDrives.first(where: { $0.driveNumber == driveNumber }) {
                // It exists! Read sector from disk image.
                statistics.lastDriveNumber = driveNumber
                statistics.readCount = statistics.readCount + 1
                (error, sectorBuffer) = virtualDrive.readSector(lsn: vLSN)
            } else {
                // It doesn't exist. Set the error code.
                error = 240;
            }

            // Respond with the sector.
            delegate?.dataAvailable(host: self, data: sectorBuffer)
            
            // Compute Checksum from sector.
            readexChecksum = compute16BitChecksum(data: sectorBuffer)
            
            processor = OP_READEXP2
        }
        
        return result
        
        func OP_READEXP2(data : Data) -> Int {
            var result = 0
            
            if data.count >= 2 {
                // We read 2 bytes into this buffer (guest's checksum).
                // Here we're expecting the checksum from the guest.
                result = 2;
                
                let guestChecksum = UInt16(data[0]) * 256 + UInt16(data[1])
                if readexChecksum != guestChecksum {
                    error = 0xF4; // OS-9 E$CRC error
                }
                
                // Send the response code to the guest.
                delegate?.dataAvailable(host: self, data: Data([UInt8(error)]))
                
                // Reset the state machine.
                resetState()
            }
            
            return result
        }
    }
    
    private func OP_REREAD(data : Data) -> Int {
        return OP_READ(data: data)
    }
    
    private func OP_READ(data : Data) -> Int {
        currentOperation = OPREADEX
        var result = 0
        var error = 0
        var sectorBuffer = Data(repeating: 0, count: 256)
        var readexChecksum : UInt16 = 0
        
        if data.count >= 5 {
            let driveNumber = data[1]
            let vLSN = Int(data[2]) << 16 + Int(data[3]) << 8 + Int(data[4])
            
            // We read 5 bytes into this buffer (OP_READEX, 1 byte drive number, 3 byte LSN)
            result = 5;
            
            // Check if the drive number exists in our virtual drive list.
            if let virtualDrive = virtualDrives.first(where: { $0.driveNumber == driveNumber }) {
                // It exists! Read sector from disk image.
                statistics.lastDriveNumber = driveNumber
                statistics.readCount = statistics.readCount + 1
                (error, sectorBuffer) = virtualDrive.readSector(lsn: vLSN)
            } else {
                // It doesn't exist. Set the error code.
                error = 240;
            }

            // Send the error code
            delegate?.dataAvailable(host: self, data: Data([UInt8(error)]))
            
            // If we have an OK response, we send the sector and checksum.
            if error == 0 {
                // Compute checksum from sector.
                readexChecksum = compute16BitChecksum(data: sectorBuffer)

                // Send the checksum.
                delegate?.dataAvailable(host: self, data: Data([UInt8(readexChecksum >> 8),UInt8(readexChecksum & 0xFF)]))

                // Send the sector.
                delegate?.dataAvailable(host: self, data: sectorBuffer)

            }

            resetState()
        }
        
        return result        
    }
}

extension Data {
    func dump() {
        dump(prefix: "")
    }
    
    func dump(prefix : String) {
        let prefix : String = prefix
        var line : String = ""
        var asciiLine : String = ""
        var asciiByte : String
        var count = 0
        let c = {
            print("\(prefix)\(line)", terminator: "")
            let s = String.init(repeating: " ", count: 40 - line.count)
            print(s, terminator: "")
            print(asciiLine, terminator: "\n")
            line = ""
            asciiLine = ""
        }
        for byte in self {
            line.append(String(format: "%02x", byte))
            if byte > 0x1f && byte < 0x7f {
                asciiByte = String(format: "%c", byte)
            } else {
                asciiByte = "."
            }
            asciiLine.append(asciiByte)
            if count % 2 == 1 {
                line.append(" ")
            }
            count = count + 1
            if count % 16 == 0 {
                c()
            }
        }
        
        if line != "" {
            c()
        }
    }
}

extension DriveWireHost {
    /// A representation of a storage device.
    public class VirtualDrive {
        /// The drive number for this drive.
        var driveNumber = 0
        
        /// A path to a file that contains the drive's data.
        var imagePath = ""
        
        private var storageContainer = Data()
        
        /// Creates a new virtual drive.
        ///
        /// - Parameters:
        ///     - driveNumber: The number to assign to this virtual drive.
        ///     - imagePath: A path to a file that contains the drive's data.
        init(driveNumber : Int, imagePath : String) throws {
            self.driveNumber = driveNumber
            self.imagePath = imagePath
            self.storageContainer = try Data(contentsOf:(URL(fileURLWithPath: imagePath)))
        }
        
        /// Reads a 256 byte sector from a virtual disk.
        ///
        /// Call this method to obtain the contents of a 256-byte sector in the virtual disk. If you pass a logical sector number that
        /// is greater than what the virtual disk contains, the function returns a 256-byte sector filled with zeros.
        ///
        /// - Parameters:
        ///     - lsn: The logical sector number to read.
        public func readSector(lsn : Int) -> (Int, Data) {
            // Seek to the offset in the file represented by the URL.
            let offsetStart = lsn * 256
            let offsetEnd = offsetStart + 256
            if storageContainer.count >= offsetEnd {
                let range: Range<Data.Index> = offsetStart..<offsetEnd
                let sector = storageContainer[range]
                // Send a 256 byte sector of zeros with no error
                return(0, sector)
            } else {
                // LSN is past point of capacity of source.
                // Send a 256 byte sector of zeros with no error
                return(0, Data(repeating: 0, count: 256))
            }
        }

        /// Writes a 256 byte sector to a virtual disk.
        ///
        /// Call this method to modify a 256-byte sector in the virtual disk. If you pass a logical sector number that
        /// is greater than what the virtual disk contains, it increases to accomodate the new sector.
        ///
        /// - Parameters:
        ///     - lsn: The logical sector number to write.
        ///     - sector: The 256-byte sector to write.
        public func writeSector(lsn : Int, sector : Data) -> Int {
            // Seek to the offset in the file represented by the URL.
            let offsetStart = lsn * 256
            let offsetEnd = offsetStart + 256
            let range: Range<Data.Index> = offsetStart..<offsetEnd
            if storageContainer.count >= offsetEnd {
                storageContainer[range] = sector
            } else {
                // LSN is past point of capacity of source.
                storageContainer.append(Data(repeating: 0xFF, count: offsetEnd - storageContainer.count))
                storageContainer[range] = sector
            }

            return 0
        }
    }
}
