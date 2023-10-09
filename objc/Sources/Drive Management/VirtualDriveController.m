/*--------------------------------------------------------------------------------------------------
//
//   File Name   :   VirtualDriveController.m
//
//   Description :   Virtual Drive Controller Implementation File
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
//  $Id: VirtualDriveController.m,v 1.3 2015/04/16 09:52:27 boisy Exp $
//------------------------------------------------------------------------------------------------*/
// Jan-12-07  BGP
// Reworked model to now use a delegate to communicate to the controller instead of
// using NSNotifcationCenter.
//------------------------------------------------------------------------------------------------*/

#import "VirtualDriveController.h"

#define MODULE_HASHTAG "VirtualDriveController"

@implementation VirtualDriveController

#pragma mark -
#pragma mark Init/Dealloc Methods

- (id)initWithCoder:(NSCoder *)coder;
{
    if ((self = [super init]))
    {
        model = [coder decodeObject];
        
        [self initDesignated];
        
        // insert the cartridge
        [self insertCartridge:[coder decodeObject]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:model];
    [coder encodeObject:[self cartridgePath]];
}

- (id)init;
{
	if ((self = [super init]) != nil)
	{
		model = [[VirtualDriveModel alloc] init];

		if (model == nil)
		{
			// There was a problem allocating the model
			return nil;
		}
	}
	
	[self initDesignated];

	return self;
}

- (void)initDesignated;
{
	if ([NSBundle loadNibNamed:@"VirtualDriveView" owner:self] == NO)
	{
		BGPDebug(@"We've got a load Nib problem\n");
	}
   
    // set ourself as the delegate of the model
    [model setDelegate:self];

	// Turn off LEDs
	[self ledOff];
	
	// Show drive as empty
	[self ejectCartridge:self];
}

- (void)dealloc;
{
}

- (VirtualDriveView *)view;
{
	return virtualDriveView;
}


#pragma mark -
#pragma mark Drive ID Methods

- (void)setDriveID:(uint16_t)driveId;
{
	[driveNumber setStringValue:[NSString stringWithFormat:@"%d", driveId]];
	[model setDriveID:driveId];
}

- (uint16_t)driveID
{
	return [model driveID];
}


#pragma mark -
#pragma mark Cartridge Methods

- (NSString *)cartridgeLabel
{
    return [model cartridgeLabel];
}

- (NSString *)cartridgePath
{
    return [model cartridgePath];
}

- (void)selectAndInsertCartridge:(id)object
{
	NSOpenPanel *filePanel = [NSOpenPanel openPanel];
	
	
	// If the drive is not empty, do nothing
	if ([self isEmpty] == NO)
	{
		return;
	}
	
	
	[filePanel setAllowsMultipleSelection:NO];
    filePanel.allowedFileTypes = [NSArray arrayWithObjects: @"dsk", @"img", @"os9", nil];
	if ([filePanel runModal] == NSOKButton)
	{
		NSArray *filenames = [filePanel URLs];
		
		NSString *cartridgeName = [[filenames objectAtIndex:0] relativePath];
		
		if (cartridgeName != nil)
		{           
			[self ejectCartridge:self];
			
			[self insertCartridge:cartridgeName];
		}
	}
}

- (BOOL)insertCartridge:(NSString *)cartridge
{
    BOOL result = NO;
    
	BGPInfo(@"Inserting Cartridge");
	
	if (cartridge != nil)
	{
		result = [model insertCartridge:cartridge];
		
        if (result == YES)
        {
            [diskLabel setStringValue:[cartridge lastPathComponent]];
            [diskLabel setEditable:NO];
            [driveDoor setHidden:NO];
            [diskLabel setHidden:NO];
        }
	}

	return result;
}

- (IBAction)ejectCartridge:(id)object
{
	BGPInfo(@"Ejecting Cartridge");
	
	[model ejectCartridge];
	[driveDoor setHidden:YES];
	[diskLabel setHidden:YES];
}

- (IBAction)resetCartridge:(id)object
{
    BGPInfo(@"Resetting Cartridge");
    
    [model resetCartridge];
}

- (BOOL)isEmpty
{
	return [model isEmpty];
}


#pragma mark -
#pragma mark Sector Access Methods

- (NSData *)readSectors:(uint32_t)lsn forCount:(uint32_t)count
{
	BGPDebug(@"->OP_READ/READEX LSN[%d] Count[%d]", lsn, count);
	
	return [model readSectors:lsn forCount:count];
}

- (void)writeSectors:(uint32_t)lsn forCount:(uint32_t)count sectors:(NSData *)sectors
{
	BGPDebug(@"->OP_WRITE/WRITEX LSN[%d] Count[%d]", lsn, count);
	
    [model writeSectors:lsn forCount:count withData:sectors];
}

- (uint32_t)sectorsRead
{
	return [model sectorsRead];
}

- (uint32_t)sectorsWritten
{
	return [model sectorsWritten];
}

- (uint32_t)totalSectorsRead
{
	return [model totalSectorsRead];
}

- (uint32_t)totalSectorsWritten
{
	return [model totalSectorsWritten];
}


#pragma mark -
#pragma mark LED Methods

- (void)ledRead
{
	[readLED setHidden:FALSE];
	[writeLED setHidden:TRUE];
}

- (void)ledWrite
{
	[writeLED setHidden:FALSE];
	[readLED setHidden:TRUE];
}

- (void)ledOff
{
	[readLED setHidden:TRUE];
	[writeLED setHidden:TRUE];
}

@end
