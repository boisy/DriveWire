/*--------------------------------------------------------------------------------------------------
//
//   File Name   :   VirtualDriveModel.m
//
//   Description :   Virtual Drive Model Implementation File
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
//  $Id: VirtualDriveModel.m,v 1.7 2015/04/16 09:52:27 boisy Exp $
//------------------------------------------------------------------------------------------------*/
// Jan-12-07  BGP
// Reworked model to now use a delegate to communicate to the controller instead of
// using NSNotifcationCenter.
//------------------------------------------------------------------------------------------------*/


#import "VirtualDriveModel.h"
#import <CoreFoundation/CoreFoundation.h>

#define MODULE_HASHTAG "VirtualDriveModel"

@implementation VirtualDriveModel

static NSRunLoop *mainRunLoop;

static NSSound *insertSound, *ejectSound;
static int instanceCount = 0;

#pragma mark Init Methods

- (id)init
{
	if ((self = [super init]) != nil)
	{
		[self initDesignated];
	}
	
	return self;
}


- (void)initDesignated
{
    // capture the main runloop
    mainRunLoop = [NSRunLoop currentRunLoop];

    // Set the initial state of the drive
	led = LED_OFF;			// LED is off
	driveID = 0;			// Drive ID is 0
	cartridgePath = nil;	// There is no cartridge yet
	sectorReadCount = 0;	// The read count is 0
	sectorWriteCount = 0;	// The write count is 0
	totalSectorReadCount = 0;	// The read count is 0
	totalSectorWriteCount = 0;	// The write count is 0
	cartridgeHandle = nil;	// There is no cartridge inserted
	sectorSize = 256;		// The default sector size is 256 bytes
   
	if (instanceCount == 0)
	{
//      NSBundle *myFrameworkBundle = [NSBundle bundleWithIdentifier:@"com.tee-boy.VirtualDrive"];
        NSBundle *myFrameworkBundle = [NSBundle bundleForClass:[self class]];
        BGPDebug(@"myFrameworksBundle = %@", [myFrameworkBundle description]);

        NSString *insertSoundPath = [myFrameworkBundle pathForResource:@"insert" ofType:@"wav"];
        insertSound = [[NSSound alloc] initWithContentsOfFile:insertSoundPath byReference:YES];
        BGPDebug(@"insertSoundPath = %@, insertSound = 0x%@", insertSoundPath, insertSound);
		[insertSound setDelegate:self];
      
        NSString *ejectSoundPath = [myFrameworkBundle pathForResource:@"eject" ofType:@"wav"];
        ejectSound = [[NSSound alloc] initWithContentsOfFile:ejectSoundPath byReference:YES];
        BGPDebug(@"ejectSoundPath = %@, ejectSound = 0x%@", ejectSoundPath, ejectSound);
	}
	
	instanceCount++;
}

- (void)dealloc
{
	instanceCount--;
	
	if (instanceCount == 0)
	{
        insertSound = nil;
        ejectSound = nil;
	}
}

- (void)setDelegate:(id)_delegate
{
	delegate = _delegate;
}


#pragma mark Drive ID Methods

- (void)setDriveID:(uint16_t)value;
{
	driveID = value;
	
	return;
}

- (uint16_t)driveID
{
	return driveID;
}


#pragma mark Cartridge Methods

- (NSString *)cartridgeLabel
{
    return [cartridgePath lastPathComponent];
}

- (NSString *)cartridgePath
{
    return cartridgePath;
}

- (BOOL)insertCartridge:(NSString *)cartridgeName
{
    BOOL result = FALSE;
    
    if (cartridgeHandle == nil)
    {
        cartridgeHandle = [NSFileHandle fileHandleForUpdatingAtPath:cartridgeName];
        
        if (cartridgeHandle != nil)
        {
            // Turn on Read LED
            [self turnOnReadLED:self time:1.0];

            // Play the "insert" sound
            [insertSound play];		
            
            // Thread-safe exchange of cartridgePath
            cartridgePath = cartridgeName;
            
            result = TRUE;
        }
    }
	
    return result;
}

- (void)ejectCartridge
{
    // Determine if this object's file handle is valid.
    if (cartridgeHandle != nil)
    {
		// There's a disk in the drive -- eject it
        [cartridgeHandle closeFile];
		
		// Reset cartridge specific counts
		sectorReadCount = 0;
		sectorWriteCount = 0;

		// Play the "eject" sound
		[ejectSound play];		
		
		cartridgePath = nil;
		cartridgeHandle = nil;
	}
    
    return;
}

- (void)resetCartridge
{
    // Determine if this object's file handle is valid.
    if (cartridgeHandle != nil)
    {
        // There's a disk in the drive -- reset it
        [cartridgeHandle closeFile];
        cartridgeHandle = [NSFileHandle fileHandleForUpdatingAtPath:cartridgePath];

        // Reset cartridge specific counts
        sectorReadCount = 0;
        sectorWriteCount = 0;
    }
    
    return;
}

- (BOOL)isEmpty
{
    BOOL result = FALSE;
    
    // Determine if the drive is empty
    if (cartridgeHandle == nil)
    {
        result = TRUE;
    }
	
    return result;
}


#pragma mark -
#pragma mark Sector Access Methods

- (NSData *)readSectors:(uint32_t)lsn forCount:(uint32_t)count
{
    NSData *result = nil;
    unsigned long long offset = lsn * sectorSize;
	
    // Determine there is a disk in the drive
    if (cartridgeHandle != nil)
    {
        // Turn on Read LED
        [self turnOnReadLED:self time:0.1];
        
        // Seek to offset based on LSN passed.
        [cartridgeHandle seekToFileOffset:offset];
        
        // Read sector at current position.
        result = [cartridgeHandle readDataOfLength:sectorSize * count];
        
        sectorReadCount += count;
        totalSectorReadCount += count;
    }
	
    // Return sectors passed.
    return result;
}

- (void)writeSectors:(uint32_t)lsn forCount:(uint32_t)count withData:(NSData *)sectors;
{
    unsigned long long offset = lsn * sectorSize;
		
    // Determine there is a disk in the drive
    if (cartridgeHandle != nil)
    {
        // Turn on write LED
        [self turnOnWriteLED:self time:0.1];
        
        // Seek to offset based on LSN passed
        [cartridgeHandle seekToFileOffset:offset];
        
        // Write sector at current position.
        [cartridgeHandle writeData:sectors];
        
        sectorWriteCount += count;
        totalSectorWriteCount += count;
    }
	
    return;
}

- (uint32_t)sectorsRead
{
	return sectorReadCount;
}

- (uint32_t)sectorsWritten
{
	return sectorWriteCount;
}

- (uint32_t)totalSectorsRead
{
	return totalSectorReadCount;
}

- (uint32_t)totalSectorsWritten
{
	return totalSectorWriteCount;
}


#pragma mark -
#pragma mark LED Control Methods

- (void)shutOffLED:(id)sender
{
	ledTimer = nil;
	
	led = LED_OFF;

    if ([delegate respondsToSelector:@selector(ledOff)])
	{
		[delegate performSelectorOnMainThread:@selector(ledOff) withObject:nil waitUntilDone:YES];
	}
}

- (void)turnOnReadLED:(id)sender time:(NSTimeInterval)timeValue;
{
	// Turn on Read LED if not already on
	if (led != LED_READ)
	{
		led = LED_READ;
		if ([delegate respondsToSelector:@selector(ledRead)])
		{
            [delegate performSelectorOnMainThread:@selector(ledRead) withObject:nil waitUntilDone:YES];
		}
	}
	
	// Reset the LED timer if it was already set
	if (ledTimer != nil)
	{
		[ledTimer invalidate];
	}
	
	ledTimer = [NSTimer timerWithTimeInterval:timeValue target:self selector:@selector(shutOffLED:) userInfo:nil repeats:NO];
	[mainRunLoop addTimer:ledTimer forMode:NSDefaultRunLoopMode];
	
	return;
}

- (void)turnOnWriteLED:(id)sender time:(NSTimeInterval)timeValue;
{
	// Turn on Write LED if not already on
	if (led != LED_WRITE)
	{
		led = LED_WRITE;
		if ([delegate respondsToSelector:@selector(ledWrite)])
		{
            [delegate performSelectorOnMainThread:@selector(ledWrite) withObject:nil waitUntilDone:YES];
		}
	}

	// Reset the LED timer if it was already set
	if (ledTimer != nil)
	{
		[ledTimer invalidate];
	}

	ledTimer = [NSTimer timerWithTimeInterval:timeValue target:self selector:@selector(shutOffLED:) userInfo:nil repeats:NO];
	[mainRunLoop addTimer:ledTimer forMode:NSDefaultRunLoopMode];

	return;
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
{
	if (aBool == YES)
	{
		[self shutOffLED:self];
	}
}

- (id)initWithCoder:(NSCoder *)coder;
{
	if ((self = [super init]))
	{
		[self initDesignated];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
}

@end
