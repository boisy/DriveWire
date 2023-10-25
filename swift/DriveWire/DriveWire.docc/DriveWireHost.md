# ``DriveWire/DriveWireHost``

## Topics

### Creating the host

- ``init(delegate:)``

### Verifying data transfers

- ``compute16BitChecksum(data:)``

### Sending information to the host

- ``send(data:)``

### Getting operational information

- ``currentTransaction``
- ``statistics``

### Getting and setting status

- ``OPGETSTAT``
- ``OPSETSTAT``
- ``OPSERGETSTAT``
- ``OPSERSETSTAT``

### Initializing and terminating

- ``OPINIT``
- ``OPTERM``
- ``OPDWINIT``
- ``OPDWTERM``
- ``OPSERINIT``
- ``OPSERTERM``

### Reading and writing virtual disks

- ``OPREAD``
- ``OPREREAD``
- ``OPREADEX``
- ``OPREREADEX``
- ``OPWRITE``
- ``OPREWRITE``
- ``OPWRITEX``
- ``OPREWRITEX``

### Managing virtual drives

- ``VirtualDrive``
- ``virtualDrives``
- ``insertVirtualDisk(driveNumber:imagePath:)``
- ``ejectVirtualDisk(driveNumber:)``


### Printing to virtual printers

- ``OPPRINT``
- ``OPPRINTFLUSH``

### Reading and writing virtual serial ports

- ``OPSERREAD``
- ``OPSERREADM``
- ``OPSERWRITE``
- ``OPSERWRITEM``

### Creating and mounting named objects

- ``OPNAMEOBJMOUNT``
- ``OPNAMEOBJCREATE``

### Detecting reset

- ``OPRESET``
- ``OPRESET2``
- ``OPRESET3``

### Getting time

- ``OPTIME``

### Debugging

- ``OPWIREBUG``
- ``OPNOP``
- ``DWWirebugOpCode``
