//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


/*!
	@header BGPSerialPort.h
	@abstract Header file for Serial Port access
	@discussion Include BGPSerialPort.h to access the class for serial port access.
	@copyright Boisy G. Pitre
	@updated 2007-06-25
 */

#include <unistd.h>
#include <fcntl.h>
#include <sys/filio.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <termios.h>

@class BGPSerialPort;

extern NSString const *kBGPSerialPortBaudRate;
extern NSString const *kBGPSerialPortWordSize;
extern NSString const *kBGPSerialPortParity;
extern NSString const *kBGPSerialPortStopBits;
extern NSString const *kBGPSerialPortMinimumReadBytes;
extern NSString const *kBGPSerialPortReadTimeout;
extern NSString const *kBGPSerialPortCTSRTS;
extern NSString const *kBGPSerialPortDTR;

/*!
 @porotocl BGPSerialPortDelegate
 @abstract Protocol that objects can adhere to for serial data
 @discussion This protocol defines a method that allows for asynchronous reception of data from the serial port.
 */
@protocol BGPSerialPortDelegate

/*!
 @method serialPort:didReceiveData:
 @abstract Called when data from the serial port is ready.
 @param port The BGPSerialPort representing the serial port where the data is coming from.
 @param data The data from the serial port.
 @discussion Data from the serial port is presented automatically to the delegate via this method.
 */
- (void)serialPort:(BGPSerialPort *)port didReceiveData:(NSData *)data;

@end

/*!
 @enum BGPSerialPortParity
 @abstract Constants for serial parity modes.
 @discussion These constants are used to set the parity mode of a serial port.
 */
typedef enum
{
    BGPSerialPortParityOdd,
    BGPSerialPortParityEven,
    BGPSerialPortParityNone
} BGPSerialPortParity;


/*!
 @interface BGPSerialPort
 @abstract Serial Port access class
 @discussion This class manages provides access to all available serial port
 devices.  It has been designed to provide a clear and concise interface
 for applications that need serial communication services.
 */
 @interface BGPSerialPort : NSObject <NSCoding>
{
	@public
    struct termios 	_originalTTYAttrs;	// original TTY attributes
    struct termios 	_ttyAttrs;			// maeleable TTY attributes
	NSCondition		*_threadCondition;
}

// settings
@property (assign) NSUInteger baudRate;
@property (assign) int wordSize;
@property (assign) BGPSerialPortParity parity;
@property (assign) int stopBits;
@property (assign) int readTimeout;
@property (assign) int minimumReadBytes;
@property (assign) BOOL hardwareHandshaking;
@property (assign) BOOL dtrState;

@property (assign) BOOL listenerThreadActive;
@property (assign) BOOL logIncomingBytes;
@property (assign) BOOL logOutgoingBytes;
@property (assign) int fd;  // file descriptor to path of serial device
@property (strong) NSString *deviceName; // the OS-friendly name of the device
@property (strong) NSString *serviceName; // the view-friendly name of the device
@property (weak) id owner; // the owner of the port
@property (weak) NSObject<BGPSerialPortDelegate> *delegate;

// Port access methods

/*!
	@method initWithDeviceName:serviceName:
	@abstract Acquires a path to the specified serial port.
	@param deviceName A pointer to the string containing the port name.
	@param serviceName A pointer to the string containing the service name.
	@discussion This method opens a port and conditions it for immediate
	use.  The default settings are 9600 baud, 8 bit word size, no parity,
	and 1 stop bit.
	@result YES if the acquisition was successful; otherwise NO.
 */
- (id)initWithDeviceName:(NSString *)deviceName serviceName:(NSString *)serviceName;

/*!
 @method openPort:error:
 @abstract Acquires a path to the specified serial port.
 @param owner A pointer to the desired owner object of the port.
 @param error The address of a pointer to an error object.
 @discussion This method opens a port and conditions it for immediate
 use.  The default settings are 9600 baud, 8 bit word size, no parity,
 and 1 stop bit.
 The data from the serial port will be presented to the user via the serialPort:didReceiveData: method.
 @result YES if the port acquisition was successful; otherwise NO.  The error object is updated in the unsuccessful case.
 */
- (BOOL)openPort:(id)owner error:(NSError **)error;

/*!
	@method closePort
	@abstract Releases a previously acquired port.
	@result YES if port was closed successfully; otherwise NO.
 */
- (BOOL)closePort;

/*!
	@method readData
	@abstract Obtains available data from the serial port.
	@result A pointer to the NSData object containing the data; nil of no data available.
 */
- (NSData *)readData;

- (NSData *)readNumberOfBytes:(NSUInteger)byteCount;

/*!
	@method writeData:
	@param data A pointer to an NSData object of the data to be written.
	@abstract Obtains available data from the serial port.
	@result YES if data was written; otherwise NO.
 */
- (BOOL)writeData:(NSData *)data;

/*!
	@method writeString:
	@param data A pointer to an NSString object of the data to be written.
	@abstract Obtains available data from the serial port.
	@result YES if data was written; otherwise NO.
 */
- (BOOL)writeString:(NSString *)data;


// Query methods

/*!
	@method isOpen
	@abstract Returns the state of the port.
	@result YES if the port is open; otherwise, NO.
 */
- (BOOL)isOpen;

/*!
	@method setPortUsingDictionary:
	@abstract A convenient method for passing settings at once.
	@param settingsDictionary The minimum number of read bytes to set.
 */
- (void)setPortUsingDictionary:(NSDictionary *)settingsDictionary;

@end
