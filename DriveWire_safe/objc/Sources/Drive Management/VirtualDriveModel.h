/*--------------------------------------------------------------------------------------------------
//
//   File Name   :   VirtualDriveModel.h
//
//   Description :   Virtual Drive Model Header File
//
//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2007 Tee-Boy
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Tee-Boy.
//  Distribution is prohibited without written permission of Tee-Boy.
//
//--------------------------------------------------------------------------------------------------
//
//  Tee-Boy                                http://www.tee-boy.com/
//  441 Saint Paul Avenue
//  Opelousas, LA  70570                   info@tee-boy.com
//
//--------------------------------------------------------------------------------------------------
//  $Id: VirtualDriveModel.h,v 1.3 2015/04/15 19:38:07 boisy Exp $
//------------------------------------------------------------------------------------------------*/

/*!
	@header VirtualDriveModel.h
	@copyright Tee-Boy
	@abstract
	@discussion
	@updated 2007-06-25
 */

#import <Cocoa/Cocoa.h>

typedef enum {LED_OFF, LED_READ, LED_WRITE} ledState;

/*!
	@class VirtualDriveModel
	The behavior of the VirtualDriveModel is modeled in the manner of a removable storage medium such as a cartridge-based hard drive.  The basis for storage is the cartridge (which is a file in reality).  Cartridges can be inserted and ejected from the drive, as well as read from and written to.
*/
@interface VirtualDriveModel : NSObject <NSCoding, NSSoundDelegate>
{
	ledState led;			// State of the LED (off, read, write)
	uint16_t driveID;		// Drive Identification number
	NSString *cartridgePath;	// Complete pathlist of the cartridge in the drive
	uint32_t sectorReadCount;
	uint32_t sectorWriteCount;
	uint32_t totalSectorReadCount;
	uint32_t totalSectorWriteCount;
    NSFileHandle *cartridgeHandle; // Handle to the cartridge (nil if drive is empty)
	NSTimer *ledTimer;
	uint16_t sectorSize;
	
	id delegate;
}

// Private methods
- (void)initDesignated;

/*!
	@method init
	@abstract Initializes an instance of the VirtualDriveModel class.
 */
- (id)init;

/*!
	@method setDelegate
	@abstract Sets the model's delegate.
*/
- (void)setDelegate:(id)_delegate;

/*!
	@method isEmpty
	@abstract Returns the status of the virtual drive, whether it is empty or has a cartridge inserted.
	@result YES if the virtual drive's bay is empty; NO if there is a cartridge inserted.
*/
- (BOOL)isEmpty;

/*!
	@method insertCartridge
	@abstract Inserts the named cartridge into the virtual drive.
	@param cartridge The pathlist to the cartridge file.  The cartridge's name becomes the filename component of the pathlist.
	@result YES if the insertion was successful; NO if a problem was encountered.
*/
- (BOOL)insertCartridge:(NSString *)cartridge;

/*!
	@method ejectCartridge
	@abstract Forces the ejection of the cartridge, if any, in the virtual drive.  Note that a cartridge must be ejected before a new one can be inserted.  Also, if the vitual drive is empty, this method has no effect.
*/
- (void)ejectCartridge;

/*!
 @method resetCartridge
 @abstract Forces the reset of the cartridge, if any, in the virtual drive. If the vitual drive is empty, this method has no effect.
 */
- (void)resetCartridge;

/*!
	@method cartridgeLabel
	@abstract Returns the name of the cartridge that is currently inserted in the virtual drive.  If the drive is empty, nil will be returned.
	@result An NSString pointer to the name on the cartridge label.
*/
- (NSString *)cartridgeLabel;

/*!
	@method cartridgePath
	@abstract Returns the pathlist of the cartridge that is currently inserted in the virtual drive.  If the drive is empty, nil will be returned.
	@result An NSString pointer to the pathlist of the cartridge.
 */
- (NSString *)cartridgePath;

/*!
	@method driveID
	@abstract Returns the ID number of the virtual drive.  This number can be used to differentiate the drive from others in a group.
	@result The drive's identification number.
*/
- (uint16_t)driveID;

/*!
	@method sectorsRead
	@abstract Returns the number of sectors that have been read for the current cartridge in the drive.
	@result A uint32_t of the number of sectors read.
*/
- (uint32_t)sectorsRead;

/*!
	@method sectorsWritten
	@abstract Returns the number of sectors that have been written for the current cartridge in the drive.
	@result A uint32_t of the number of sectors written.
*/
- (uint32_t)sectorsWritten;

/*!
	@method totalSectorsRead
	@abstract Returns the number of sectors that have been read since the virtual drive has been created.
	@result A uint32_t of the number of sectors read.
*/
- (uint32_t)totalSectorsRead;

/*!
	@method totalSectorsWritten
	@abstract Returns the number of sectors that have been written since the virtual drive has been created.
	@result A uint32_t of the number of sectors written.
*/
- (uint32_t)totalSectorsWritten;

	/*!
	@method setDriveID
	@abstract Sets the ID number of the virtual drive
	@discussion The drive ID is useful when identifying a single virtual drive in a collection of drives.
	@param id The number to associate with the virtual drive.
*/
- (void)setDriveID:(uint16_t)value;

/*!
	@method readSectors
	@abstract Obtains the desired number of sectors from the cartridge inserted into the virtual drive.
	@param lsn The starting logical sector number where the read will occur.
	@param count The number of sectors to read.
	@result An NSData pointer holding the address of the sector data.  If an error occurred, nil is returned.
*/
- (NSData *)readSectors:(uint32_t)lsn forCount:(uint32_t)count;

/*!
	@method writeSectors
	@abstract Writes the specified number of sectors to the cartridge inserted into the virtual drive.	
	@param lsn The starting logical sector number where the write will occur.
	@param count The number of sectors to write.
	@param sectors A pointer to the sector data to write.
*/
- (void)writeSectors:(uint32_t)lsn forCount:(uint32_t)count withData:(NSData *)sectors;


- (void)turnOnReadLED:(id)sender time:(NSTimeInterval)timeValue;

- (void)turnOnWriteLED:(id)sender time:(NSTimeInterval)timeValue;


@end

@interface NSObject (VirtualDriveModelDelegate)

- (void)ledRead;
- (void)ledWrite;
- (void)ledOff;

@end
