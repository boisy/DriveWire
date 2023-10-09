#  DriveWire 

This is the official repository for DriveWire.

DriveWire defines a standard for guest computers to access input/output resources on a host computer. This model gives the guest computer the appearance that it is directly connected to a large storage device, when in fact, connectivity is achieved using a serial cable connected to the host.

There are distinct advantages in utilizing DriveWire as a storage medium:

- **Cost and space savings:** No additional hardware is needed for a guest to use mass storage; no floppy controller, hard drive controller or hard drives are required.
- **Remote operation:** The serial cable that tethers the guest to the host can extend for some length, allowing the guest to be positioned a considerable distance.
- **Easy data management:** Virtual disks that reside on the host can be easily copied, emailed or archived for backup purposes.

The essence of communication between the guest and host is a documented set of uni- and bi-directional messages called *transactions*. Each transaction is composed of one or more packets, which are passed between the guest and host through a serial line connection.

[The DriveWire Specification](https://github.com/boisy/DriveWire/wiki/DriveWire-Specification) provides the information needed to implement both a host and a guest.

## Host platforms

This repository has DriveWire host implementations for supported platforms:

- UNIX: [C](c)
- Mac: [Swift](swift) and [Objective-C](objc)
- Windows: [Delphi](delphi)

There are other repositories that host DriveWire implementations:

- Python: Mike Furman hosts [pyDriveWire](https://github.com/n6il/pyDriveWire).
- Java: Aaron Wolfe's [DriveWire 4 Server](https://sourceforge.net/projects/drivewireserver/).

## History

DriveWire began life in 2003 as a solution for the Tandy Color Computer. Floppy drives were starting to wane and modern storage options for older computer systems were still years from being developed. [Boisy Pitre](http://www.pitre.org/) gave [this talk](https://www.youtube.com/watch?v=-w7X0CfqFbc&t=462s) on DriveWire's history and development at Tandy Assembly on October 2, 2021.

In 2012, Aaron Wolfe and Boisy Pitre expanded the protocol to include networking services. Aaron went on to create DriveWire 4, a Java-based host.

Today, DriveWire is still in use. There are a number of [YouTube videos](https://www.youtube.com/results?search_query=drivewire+coco) showing it in action.
