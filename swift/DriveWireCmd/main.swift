//
//  main.swift
//  DriveWireCmd
//
//  Created by Boisy Pitre on 10/8/23.
//

import Foundation

let d = DriveWireSerialDriver(portName: "/dev/cu.usbserial-FTVA079L", baudRate: 57600)
//let d = DriveWireSerialDriver(serialPort: "/dev/cu.usbserial-FT079LCR3", baudRate: 230400)
d.logging = true
do {
//    try d.host?.insertVirtualDisk(driveNumber: 0, imagePath: "/Users/boisy/Projects/coco-shelf/nitros9/level1/f256/NOS9_6809_L1_v030300_f256_dw.dsk")
//    try d.host?.insertVirtualDisk(driveNumber: 0, imagePath: "/Users/boisy/Projects/coco-shelf/nitros9/level2 /f256/NOS9_6809_L2_v030300_f256_dw.dsk")
//    try d.host?.insertVirtualDisk(driveNumber: 1, imagePath: "/Users/boisy/Downloads/DynaCalc (Tandy) (OS-9)/dyncalc.dsk")
//    try d.host?.insertVirtualDisk(driveNumber: 1, imagePath: "/Users/boisy/Downloads/Rogue (Tandy) (OS-9) (Coco 3)/ROGUE512.DSK")
    try d.host?.insertVirtualDisk(driveNumber: 0, imagePath: "/Users/boisy/Projects/coco-shelf/nitros9/level1/atari/NOS9_6809_L1_v030300_atari.dsk")
} catch {
    
}

print("Hello, World!")

