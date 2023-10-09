//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2007 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


/*!
	@header BGPSerialManager.h
	@copyright BP
	@abstract Serial device manager class.
	@discussion BGPSerialManager manages the serial devices on a system.
	@updated 2007-06-25
 */

#import <Foundation/Foundation.h>

#import "BGPLog.h"
#import "BGPSerialPort.h"

	
/*!
	@class BGPSerialManager
	@discussion The BGPSerialManager class manages access to serial
	port devices.
 */
@interface BGPSerialManager : NSObject
{
	NSMutableDictionary		*portList;
	Boolean					allowedToRun;
}


/*!
 @method defaultManager
 @abstract Returns a global, default manager
 @result The pointer to the initialized manager (same for all calls).
 */
+ (BGPSerialManager *)defaultManager;

/*!
	@method init
	@abstract Initializes the class.
	@result The pointer to the initialized object.
 */
- (id)init;


#pragma mark Query methods

/*!
	@method doesPortExist
	@abstract Determines if a serial port exists.
	@param name Pointer to the port name to verify.
	@discussion This method determines if a particular port exists on the
	system.  The passed name must be a service name, and not a device name.
	@result YES if the port exists, otherwise NO.
*/
- (BOOL)doesPortExist:(NSString *)name;


/*!
	@method isPortAvailable
	@abstract Determines if the passed port name is available for use.
	@discussion Ports are available only if they are not already opened by
	another thread.  This method will alert the caller to the
	availability of a named port.
	@result YES if the port is available; otherwise NO.
*/
- (BOOL)isPortAvailable:(NSString *)name;


/*!
	@method reservePort
	@abstract Marks a port as reserved.
	@discussion Reserving a serial port marks that port as being in use. It
	cannot be reserved again until it is released with <i>releasePort</i>.
	If the passed port name is already reserved, then <i>nil</i> is returned.
    The port's owner is marked, but the port is not opened upon reserve.
	@param name Pointer to the port name to reserve.
	@param object Pointer to the object which will "own" the port.
	@param error The address of a pointer to an error object.
	@result id of the port if it was properly reserved; nil if not.
 */
- (BGPSerialPort *)reservePort:(NSString *)name forOwner:(id)object error:(NSError **)error;


/*!
	@method releasePort
	@abstract Releases a previously reserved port.
	@discussion This method will release a previously reserved port so that
	it can be claimed by another object.  If the passed port name is already
	released, then this method does nothing.
	If the port was opened, it is closed upon release.
	@param name Pointer to the port name to release.
	@result YES if the port was properly released; NO if not.
 */
- (BOOL)releasePort:(NSString *)name;


/*!
	@method availablePorts
	@abstract Returns a dictionary of available ports.
	@discussion Applications that use serial ports are typically interested
	in allowing the user to select from a list of available ports on the
	system. This method returns an NSDictionary that contains key/value
	pairs of the port name/BGPSerialPort of non-reserved serial ports on the system.
	@result A dictionary containing the port name as key and device name as
	value EXCEPT for Bluetooth-PDA-Sync and Bluetooth-Modem. Those two are
	stripped out.
 */
- (NSMutableDictionary *)availablePorts;

/*!
 @method findPortThatRespondsWith:toMessage:withBaudRate:withinTimeInterval:
 @abstract Returns the port that has a specific response to a message at a specified baudrate within a specific time
 @discussion This method attempts to locate a specific port that will respond
 to a message. Use this method when you want to find a port that is connected
 to a unique piece of hardware.
 Note that if a port is not open, it will be scanned, even if it is reserved.
 @result A dictionary containing the port name as key and device name as
 value EXCEPT for Bluetooth-PDA-Sync and Bluetooth-Modem. Those two are
 stripped out.
 */
- (NSString *)findPortThatRespondsWith:(NSData *)response
							 toMessage:(NSData *)message 
						  withBaudRate:(NSUInteger)baudRate
					withinTimeInterval:(NSTimeInterval)timeInterval;

@end
