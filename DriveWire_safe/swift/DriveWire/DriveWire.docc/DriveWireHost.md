# ``DriveWire/DriveWireHost``

## Topics

### Creating the host

- ``init(delegate:)``

### Verifying data transfers

- ``compute16BitChecksum(data:)``

### Inserting and ejecting virtual disks

- ``insertVirtualDisk(driveNumber:imagePath:)``
- ``ejectVirtualDisk(driveNumber:)``

### Sending information to the host

- ``send(data:)``

### Getting operational information

- ``currentOperation``
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

### Printing to virtual printers

- ``OPPRINT``
- ``OPPRINTFLUSH``

### Reading and writing virtual serial ports

- ``virtualDrives``
- ``OPSERREAD``
- ``OPSERREADM``
- ``OPSERWRITE``
- ``OPSERWRITEM``

### Creating and mounting named objects

- ``OPNAMEOBJMOUNT``
- ``OPNAMEOBJCREATE``

### Handling resets

- ``OPRESET``
- ``OPRESET2``
- ``OPRESET3``

### Getting time

- ``OPTIME``

### Debugging

- ``OPWIREBUG``
- ``OPNOP``
