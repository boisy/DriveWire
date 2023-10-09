#  DriveWire 

DriveWire is a protocol for guest computers to access input/output resources on a host computer. DriveWire provides a number of advantages to smaller computers with limited storage and networking capabilities:

- **Cost and space savings.** The guest requires no mass storage or networking hardware be physically connected.
- **Remote operation.** Connections such as a wireless device or serial cable is all that's needed.
- **Convenient data management.** It's easy to copy, backup, and share virtual disks since they reside on the host.

The basis of communication between the guest and the host is the set of  uni- and bi-directional messages called *transactions*. A transaction is composed of one or more packets that the guest and host pass to each other.

This repository is the place for documenting the DriveWire protocol.
