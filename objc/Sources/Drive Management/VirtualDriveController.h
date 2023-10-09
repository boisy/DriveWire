/*--------------------------------------------------------------------------------------------------
//
//   File Name   :   VirtualDriveController.h
//
//   Description :   Virtual Drive Controller Header File
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
//  $Id: VirtualDriveController.h,v 1.1 2009/03/14 16:27:43 boisy Exp $
//------------------------------------------------------------------------------------------------*/


/*!
	@header VirtualDriveController.h
	@copyright Tee-Boy
	@abstract
	@discussion
	@updated 2007-06-25
 */

#import <Cocoa/Cocoa.h>
#import "VirtualDriveView.h"
#import "VirtualDriveModel.h"


@interface VirtualDriveController : NSObject <NSCoding>
{
	VirtualDriveModel *model;
	
	// Outlets to asset components of VirtualDriveView
	IBOutlet VirtualDriveView *virtualDriveView;
	IBOutlet NSImageView *driveFacePlate;
	IBOutlet NSImageView *driveDoor;
	IBOutlet NSImageView *readLED;
	IBOutlet NSImageView *writeLED;
	IBOutlet NSTextField *diskLabel;
	IBOutlet NSTextField *driveNumber;
}

- (void)initDesignated;

- (VirtualDriveView *)view;

#pragma mark Cartridge methods

- (BOOL)isEmpty;
- (IBAction)selectAndInsertCartridge:(id)object;
- (BOOL)insertCartridge:(NSString *)cartridge;
- (IBAction)ejectCartridge:(id)object;
- (IBAction)resetCartridge:(id)object;
- (NSString *)cartridgeLabel;
- (NSString *)cartridgePath;


#pragma mark  Drive status methods

- (uint16_t)driveID;
- (uint32_t)sectorsRead;
- (uint32_t)sectorsWritten;
- (uint32_t)totalSectorsRead;
- (uint32_t)totalSectorsWritten;

// Set drive's identification number
- (void)setDriveID:(uint16_t)driveId;

// Returns a number of sectors
- (NSData *)readSectors:(uint32_t)lsn forCount:(uint32_t)count;

// Writes the number of passed sectors to the cartridge
- (void)writeSectors:(uint32_t)lsn forCount:(uint32_t)count sectors:(NSData *)sectors;

// LED handlers
- (void)ledRead;
- (void)ledWrite;
- (void)ledOff;

@end
