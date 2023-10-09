# DriveWire Server for macOS
This is the official DriveWire server for macOS. Integrations are performed as commits are made, and Sparkle is used for in-app updating.

## Obtaining Dependency Frameworks with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Xcode projects which automates and simplifies the process of using 3rd-party libraries. You can install it with the following command:

```bash
$ sudo gem install cocoapods
```

## Building

Once you have installed CocoaPods, run the following command:

```bash
$ pod install
```

This will fetch the required frameworks and create the DriveWire.xcworkspace file. You can open the workspace file in Xcode and build the server. Use Xcode 9 or later.

## AppleScript Support
You can use AppleScript to communicate with DriveWire server for macOS using the Script Editor application on the Mac. This is convenient if you want to automate your disk image creation and test workflow. Below are several "recipes" that you can use. Note that each script accesses the "first document" but you can also reference a document by name if you have more than one opened.


### Set the baud rate:
```AppleScript
tell application "DriveWire"
    tell server of first document
        set baudRate to 57600
    end tell
end tell
```

### Eject the virtual disk in drive 3:
```AppleScript
tell application "DriveWire"
    tell server of first document
        -- an error is returned if the drive number is illegal
        eject drive 3
    end tell
end tell
```

### Insert virtual disk "mydisk.dsk" into drive 0 and set the serial port:
```AppleScript
tell application "DriveWire"
    tell server of first document
        -- the insert command ejects any virtual disk from the drive before inserting the new one
        insert image POSIX path of ("/Users/boisy/mydisk.dsk") into drive 0
        change to port "usbserial-FT079LCRB"
    end tell
end tell
```

### Reload the virtual disk in drive 0:
This command is useful if you have altered the contents of the underlying disk image and want the server to detect those changes.

```AppleScript
tell application "DriveWire"
    tell server of first document
    -- the insert command ejects any virtual disk from the drive before inserting the new one
        reload drive 0
    end tell
end tell
```

### Turn off the serial port:
Sometimes you need to get DriveWire out of the way and not control the serial port.

```AppleScript
tell application "DriveWire"
    tell server of first document
    -- turn off the serial port
        change to port ""
    end tell
end tell
```

### Create a new document, set the baud rate to 57,600 bits per second, and insert a few disk images:
```AppleScript
tell application "DriveWire"
    set newDocument to make new document
    tell server of newDocument
        set baudrate to 57600
        -- an error is returned if the drive number is illegal or the path does not exist
        insert image POSIX path of ("/Users/boisy/nitros9.dsk") into drive 0
        insert image POSIX path of ("/Users/boisy/utilities.dsk") into drive 1
    end tell
end tell
```

## DriveWire Specification
This server follows the specifications [found here]( https://sourceforge.net/p/drivewireserver/wiki/DriveWire_Specification/).


