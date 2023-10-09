//
//  main.swift
//  DriveWireCmd
//
//  Created by Boisy Pitre on 10/8/23.
//

import Foundation
import DriveWire

let d = DriveWireSerialDriver(serialPort: "/dev/cu.usbserial-FT079LCR3")
do {
    try d.host?.insertVirtualDisk(driveNumber: 0, imagePath: "/Users/boisy/Projects/coco-shelf/nitros9/level1/f256/NOS9_6809_L1_v030300_f256.dsk")
} catch {
    
}

d.run()
print("Hello, World!")

