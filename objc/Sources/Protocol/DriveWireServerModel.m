//
//  DriveWireServerModel.m
//  DriveWire
//
//  Created by Boisy Pitre on 12/8/04.
//  Copyright 2008 BGP. All rights reserved.
//

#import "DriveWireServerModel.h"

#define MODULE_HASHTAG "DriveWireServer"

NSString *const kDriveWireStatusNotification = @"com.drivewire.DriveWireStatusNotification";
NSString *const kBaudRateSelectedNotification = @"com.drivewire.BaudRateSelectionNotification";
NSString *const kSerialPortChangedNotification = @"com.drivewire.SerialPortChangedNotification";

@interface NSObject(DriveWireServerScriptingContainer)

// An informal protocol to which scriptable containers of WS4AgentPlugIn must conform.
- (NSScriptObjectSpecifier *)objectSpecifierForModel:(DriveWireServerModel *)model;

@end

@interface DriveWireServerModel ()

// Protocol management variables
@property (assign) SEL						currentState;
@property (assign) Boolean					validateWithCRC;
@property (weak)   NSTimer					*watchDog;

@property (strong) NSMutableData *serialBuffer;

// SERWRITEM variables
@property (assign) u_int8_t serwritemChannelNumber;
@property (assign) u_int8_t serwritemBytesFollowing;
@property (assign) u_int8_t fastwriteChannel;

@end

@implementation DriveWireServerModel

@synthesize baudRate = _baudRate;

#define MAX_TIME_BEFORE_RESET 0.5

static BGPSerialManager *fSerialManager = nil;


#pragma mark -
#pragma mark Private Methods

- (void)postStatistics:(NSDictionary *)dictionary;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDriveWireStatusNotification
                                                        object:self
                                                      userInfo:@{@"statistics" : dictionary}];
}


#pragma mark -
#pragma mark Init/Dealloc Methods

- (void)initCommon;
{
    int32_t		i;
    
    NSArray		*keys = [NSArray arrayWithObjects:
                         @"OpCode",
                         @"DriveNumber",
                         @"LSN",
                         @"ReadCount",
                         @"WriteCount",
                         @"ReReadCount",
                         @"ReWriteCount",
                         @"GetStat",
                         @"SetStat",
                         @"Checksum",
                         @"Error",
                         nil];
    
    NSArray		*objects = [NSArray arrayWithObjects:
                            @"NONE",
                            @"0",
                            @"0",
                            @"0",
                            @"0",
                            @"0",
                            @"0",
                            @"NONE",
                            @"NONE",
                            @"0",
                            @"0",
                            nil];
    
    NSArray		*registerKeys = [NSArray arrayWithObjects:
                                 @"CC",
                                 @"DP",
                                 @"A",
                                 @"B",
                                 @"E",
                                 @"F",
                                 @"X",
                                 @"Y",
                                 @"U",
                                 @"S",
                                 @"PC",
                                 nil];
    
    NSArray		*registerObjects = [NSArray arrayWithObjects:
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    [NSNumber numberWithInt:0],
                                    nil];
				
    // Set drive numbers.
    for (i = 0; i < [driveArray count]; i++)
    {
        [[driveArray objectAtIndex:i] setDriveID:i];
    }
    
    // Allocate stats manager.
    statistics = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys];
    
    // Allocate registers dictionary.
    registers = [[NSMutableDictionary alloc] initWithObjects:registerObjects
                                                     forKeys:registerKeys];
    
    portDelegate = nil;
    
    if (version > 1)
    {
        self.validateWithCRC = NO;		/* We will do checksums on the data. */
    }
    else
    {
        self.validateWithCRC = YES;		/* We will do CRCs on the data. */
    }
    
    if (fSerialManager == nil)
    {
        fSerialManager = [[BGPSerialManager alloc] init];		
    }
    
    // Set up the devices
    fSerialPortNames = [[BGPSerialManager defaultManager] availablePorts];
    
    // Set up state variables
    [self resetState:nil];
    
    // Setup printer buffer
    printBuffer = [[NSMutableData alloc] init];
    
    // Setup array of 16 serial data buffers
    NSUInteger basePort = 6809;
    self.serialChannels = [NSMutableArray array];
    for (i = 1; i < 17; i++)
    {
        VirtualSerialChannel *channel = [[VirtualSerialChannel alloc] initWithModel:self number:i port:basePort + i];
        [self.serialChannels addObject:channel];
    }

    self.screens = [NSMutableArray array];
    for (i = 1; i < 17; i++)
    {
        VirtualScreenWindowController *screen = [[VirtualScreenWindowController alloc] initWithModel:self number:i port:basePort + i];
        [self.screens addObject:screen];
    }
    
    return;
}

- (id)init
{
    return [self initWithDocument:nil version:DW_DEFAULT_VERSION];
}

- (id)initWithDocument:(NSDocument *)document version:(int)versionNumber;
{
	if ((self = [super init]))
	{
		int32_t i;
        
        BGPDebug(@"DriveWireServerModel initWithDocument:%@ version:%d", document, versionNumber);
        
        // Allocate our array of drives
		driveArray = [[NSMutableArray alloc] init];

		for (i = 0; i < 4; i++)
		{
			VirtualDriveController *drive;
		
			drive = [[VirtualDriveController alloc] init];
			[driveArray insertObject:drive atIndex:i];
		}

		version = versionNumber;
		
		// set defaults
        self.statState = FALSE;
        self.logState = FALSE;
        self.wirebugState = FALSE;
		[self setBaudRate:115200];
        self.memAddress = 0;

		fCurrentPort = nil;

		// Call the common init routine to do common initializaiton		
		[self initCommon];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if ((self = [super init]))
    {
        NSString *savedPort;
        
        driveArray = [coder decodeObjectForKey:@"driveArray"];
        version = [coder decodeIntegerForKey:@"version"];
        savedPort = [coder decodeObjectForKey:@"port"];
        self.statState = [coder decodeBoolForKey:@"statState"];
        self.logState = [coder decodeBoolForKey:@"logState"];
        _baudRate = [coder decodeIntForKey:@"baudRate"]; if (_baudRate == 0) { _baudRate = 115200; }
        
        [self initCommon];
        
        fCurrentPort = nil;
        
        [self setCommPort:savedPort];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    NSArray *encodedDriveArray = [driveArray subarrayWithRange:NSMakeRange(0, 4)];
    [coder encodeObject:encodedDriveArray forKey:@"driveArray"];
    [coder encodeInteger:version forKey:@"version"];
    [coder encodeObject:fCurrentPort forKey:@"port"];
    [coder encodeBool:self.statState forKey:@"statState"];
    [coder encodeBool:self.logState forKey:@"logState"];
    [coder encodeInteger:self.baudRate forKey:@"baudRate"];
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    BGPDebug(@"DriveWireServerModel dealloc");
    
    // Remove ourself as observer from any notifications
    [nc removeObserver:self];
    
    self.serialChannels = nil;
    printBuffer = nil;
    statistics = nil;
    registers = nil;
    
    driveArray = nil;
    [fSerialManager releasePort:fCurrentPort];
    fSerialPortNames = nil;
}


#pragma mark -
#pragma mark Watchdog Methods

- (void)setupWatchdog;
{
    [self invalidateWatchdog];
    self.watchDog = [NSTimer scheduledTimerWithTimeInterval:MAX_TIME_BEFORE_RESET
                                                target:self
                                              selector:@selector(resetState:)
                                              userInfo:nil
                                               repeats:NO];
}

- (void)invalidateWatchdog;
{
    [self.watchDog invalidate];
}


// This method communicates with the serial manager to reserve a specific
// communications port.  It returns YES if the port was successfully
// reserved, or NO if it wasn't.
- (BOOL)setCommPort:(NSString *)selectedPort;
{
    BOOL result = FALSE;
    
	BGPSerialPort *newPort;
	
	// If we're asked to set the same serial port we have set, return YES
	if ([selectedPort compare:fCurrentPort] == NSOrderedSame)
	{
		return YES;
	}
	
	// If we are passed "No Device", release the current port and return YES
	if ([selectedPort compare:@"No Device"] == NSOrderedSame)
	{
		[fSerialManager releasePort:fCurrentPort];
		fCurrentPort = nil;
		
        [[NSNotificationCenter defaultCenter] postNotificationName:kSerialPortChangedNotification
                                                            object:self
                                                          userInfo:@{@"port" : [NSNull null]}];

        return YES;
	}
	
	// If the port passed is not available, return NO
	if ([fSerialManager isPortAvailable:selectedPort] == NO)
	{
		return NO;
	}
	
	// Attempt to reserve the port passed.
	NSError *error = nil;
	newPort = [fSerialManager reservePort:selectedPort forOwner:self error:&error];

	if (newPort == nil)
	{
		return NO;
	}
	
	// At this point, we've reserved the requested port.
	// Release our fCurrentPort and point it to the passed port
	[fSerialManager releasePort:fCurrentPort];
	fCurrentPort = selectedPort;
	fPort = newPort;
    [self setBaudRate:self.baudRate];  // force the setting of the baud rate
    [fPort setPortUsingDictionary:@{kBGPSerialPortDTR : @TRUE}];
    [fPort setHardwareHandshaking:NO];

    [fPort setDelegate:self];
	[self setPortDelegate:fPort];
    
    
    result = [fPort openPort:self error:&error];
    
    if (result == YES)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSerialPortChangedNotification
                                                            object:self
                                                          userInfo:@{@"port" : fPort}];
    }
    return result;
}

- (id)portDelegate
{
	return portDelegate;
}

- (void)setPortDelegate:(id)handler
{
	portDelegate = handler;
	BGPDebug(@"Now listening for data from device %@\n", [handler serviceName]);
}

- (NSMutableArray *)driveArray
{
	return driveArray;
}

- (NSUInteger)baudRate;
{
    return _baudRate;
}

- (void)setBaudRate:(NSUInteger)baud
{
	_baudRate = baud;
    NSUInteger oldBaudRate = [fPort baudRate];
    NSUInteger newBaudRate = baud;

    // We have to close and reopen the port when we change the baud rate now
    if (oldBaudRate != newBaudRate) {
        [fPort setBaudRate:newBaudRate];
        if ([fPort isOpen] == TRUE)
        {
            [fPort closePort];
            [fPort openPort:self error:nil];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kBaudRateSelectedNotification
                                                        object:self
                                                      userInfo:@{@"baudRate" : [NSNumber numberWithInteger:baud]}];
}

- (NSString *)serialPort
{
	return fCurrentPort;
}


#pragma mark -
#pragma mark Data Integrity Calculation Routines

- (uint16_t)compute16BitChecksum:(const u_char *)data length:(int)length
{
	uint16_t lastChecksum = 0x0000;
	uint8_t *ptr;
	
	ptr = (uint8_t *)data;
	while (length--)
	{
		lastChecksum += *(ptr++);
	}
	
	return lastChecksum;
}

- (uint8_t)compute8BitChecksum:(const u_char *)data length:(int)length
{
	uint8_t lastChecksum = 0x00;
	uint8_t *ptr;
	
	ptr = (uint8_t *)data;
	while (length--)
	{
		lastChecksum += *(ptr++);
	}
	
	return lastChecksum;
}

- (uint16_t)computeCRC:(const u_char *)data length:(int)length
{
	uint16_t i, crc = 0;
	uint16_t *ptr = (uint16_t *)data;
	
	while (--length >= 0)
	{
		crc = crc ^ *ptr++ << 8;
		
		for (i = 0; i < 8; i++)
		{
			if (crc & 0x8000)
			{
				crc = crc << 1 ^ 0x1021;
			}
			else
			{
				crc = crc << 1;
			}
		}
	}
	
	return (crc & 0xFFFF);
}


#pragma mark -
#pragma mark Data Processing Routines

// BGPSerialPort data callback method
- (void)serialPort:(BGPSerialPort *)sender didReceiveData:(NSData *)serialData;
{
    NSUInteger bytesConsumed = 0;
    
    if (nil == self.serialBuffer)
    {
        self.serialBuffer = [NSMutableData data];
    }
    
    // append incoming data
    [self.serialBuffer appendData:serialData];
    
    do
    {
        // invoke selector and get bytes consumed
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                    [[self class] instanceMethodSignatureForSelector:self.currentState]];
        [invocation setSelector:self.currentState];
        [invocation setArgument:&_serialBuffer atIndex:2];
        [invocation setTarget:self];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
        [invocation getReturnValue:&bytesConsumed];
        
        if (bytesConsumed > 0)
        {
            // chop off consumed bytes
            [self.serialBuffer replaceBytesInRange:NSMakeRange(0, bytesConsumed) withBytes:nil length:0];
        }
    } while (bytesConsumed > 0 && [self.serialBuffer length] > 0);
    
    
    return;
}

- (NSUInteger)OP_OPCODE:(NSData *)data;
{
    u_char byte = *(u_char *)[data bytes];
                    
    [self setupWatchdog];

    if (byte >= 0x80 && byte <= 0x8E)
    {
        // FASTWRITE serial
        self.fastwriteChannel = byte & 0x0F;
        self.currentState = @selector(OP_FASTWRITE:);
    }
    else
    if (byte >= 0x91 && byte <= 0x9E)
    {
        // FASTWRITE virtual screen
        self.fastwriteChannel = (byte & 0x0F) - 1;
        self.currentState = @selector(OP_FASTWRITE_VirtualScreen:);
    }
    else
    {
        // Determine next action to take.
        switch (byte)
        {
            case _OP_SERREAD:
                [self OP_SERREAD];
                break;
                
            case _OP_NOP:
                [self OP_NOP];
                break;
                
            case _OP_TIME:
                [self OP_TIME];
                break;
                
            case _OP_PRINT:
                self.currentState = @selector(OP_PRINT:);
                break;
                
           case _OP_PRINTFLUSH:
                [self OP_PRINTFLUSH];
                break;
              
            case _OP_INIT:
                [self OP_INIT];
                break;
                
            case _OP_TERM:
                [self OP_TERM];
                break;
                
            case _OP_READ:
                self.currentState = @selector(OP_READ:);
                break;
                
            case _OP_READEX:
                self.currentState = @selector(OP_READEX:);
                break;
                
            case _OP_REREAD:
                self.currentState = @selector(OP_REREAD:);
                break;
                
            case _OP_REREADEX:
            case '?':
                self.currentState = @selector(OP_REREADEX:);
                break;
                
            case _OP_WRITE:
                self.currentState = @selector(OP_WRITE:);
                break;
                
            case _OP_REWRITE:
                self.currentState = @selector(OP_REWRITE:);
              break;
                
            case _OP_GETSTAT:
                self.currentState = @selector(OP_GETSTAT:);
                break;
                
            case _OP_SETSTAT:
                self.currentState = @selector(OP_SETSTAT:);
                break;
                
            case _OP_RESET1:
            case _OP_RESET2:
            case _OP_RESET3:
                [self OP_RESET];
                break;
                
            case _OP_NAMEOBJ_MOUNT:
                self.currentState = @selector(OP_NAMEOBJ_MOUNT:);
                break;
                
            case _OP_SERINIT:
                self.currentState = @selector(OP_SERINIT:);
                break;
                
            case _OP_SERTERM:
                self.currentState = @selector(OP_SERTERM:);
                break;
                
            case _OP_SERGETSTAT:
                self.currentState = @selector(OP_SERGETSTAT:);
                break;
                
            case _OP_SERSETSTAT:
                self.currentState = @selector(OP_SERSETSTAT:);
                break;
                
            case _OP_SERREADM:
                self.currentState = @selector(OP_SERREADM:);
                break;
                
            case _OP_SERWRITE:
                self.currentState = @selector(OP_SERWRITE:);
                break;
                
            case _OP_SERWRITEM:
                self.currentState = @selector(OP_SERWRITEM:);
                break;
                
            case _OP_DWINIT:
                self.currentState = @selector(OP_DWINIT:);
                break;
                
    // WireBug Section
            case _OP_WIREBUG_MODE:
                self.currentState = @selector(OP_WIREBUG_MODE:);
                break;
    #if 0
                
            case _OP_RESYNC:
    #endif
            default:
                // Resync in case of bad data transfer
                [self OP_RESYNC];
                break;
        }
    }
    
    return 1;
}

- (void)OP_NOP;
{
    [statistics setObject:@"OP_NOP" forKey:@"OpCode"];
    [self postStatistics:statistics];
    [self resetState:nil];
}

- (void)OP_PRINTFLUSH;
{
	[statistics setObject:@"OP_PRINTFLUSH" forKey:@"OpCode"];
    [self postStatistics:statistics];
    [self flushPrinterBuffer];
    [self resetState:nil];
}

- (void)flushPrinterBuffer;
{
    NSDictionary *d = [NSDictionary dictionaryWithObject:[printBuffer copy] forKey:@"PrintData"];
    [printBuffer setLength:0];
    [self.delegate updatePrinterView:d];
    [self resetState:nil];
}

#define  MAX_SIZE_BEFORE_PRINTING   256

- (NSUInteger)OP_DWINIT:(NSData *)data;
{
    u_char byte = *(u_char *)[data bytes];
	
	[statistics setObject:@"OP_DWINIT" forKey:@"OpCode"];
	[statistics setObject:[NSString stringWithFormat:@"%d", byte] forKey:@"Byte"];
    [self postStatistics:statistics];

	// send response 0x04 indicating DriveWire 4 support
	[portDelegate writeData:[NSData dataWithBytes:"\x04" length:1]];

    [self resetState:nil];
   
    return 1;
}

- (NSUInteger)OP_PRINT:(NSData *)data;
{
    u_char byte = *(u_char *)[data bytes];
	
    [printBuffer appendBytes:&byte length:1];
    [statistics setObject:@"OP_PRINT" forKey:@"OpCode"];
    [statistics setObject:[NSString stringWithFormat:@"%d", byte] forKey:@"Byte"];
    [self postStatistics:statistics];

    if ([printBuffer length] > MAX_SIZE_BEFORE_PRINTING)
    {
        [self flushPrinterBuffer];
    }

    [self resetState:nil];

    return 1;
}

- (void)OP_INIT
{
	[statistics setObject:@"OP_INIT" forKey:@"OpCode"];
    [self postStatistics:statistics];
    [self resetState:nil];
}

- (void)OP_TERM
{
	[statistics setObject:@"OP_TERM" forKey:@"OpCode"];
    [self postStatistics:statistics];
    [self resetState:nil];
}

- (void)OP_RESET
{
	// Reset all statistics
	[statistics setObject:@"OP_RESET" forKey:@"OpCode"];
	[statistics setObject:@"0" forKey:@"LSN"];
	[statistics setObject:@"0" forKey:@"ReadCount"];
	[statistics setObject:@"0" forKey:@"WriteCount"];
	[statistics setObject:@"0" forKey:@"ReReadCount"];
	[statistics setObject:@"0" forKey:@"ReWriteCount"];
	[statistics setObject:@"NONE" forKey:@"GetStat"];
	[statistics setObject:@"NONE" forKey:@"SetStat"];
	[statistics setObject:@"0" forKey:@"Error"];
	[statistics setObject:@"00000" forKey:@"Checksum"];
    [self postStatistics:statistics];

    // Set WireBug state to FALSE
    [self setWirebugState:false];

    // Reset all serial channels
    for (VirtualSerialChannel *ch in self.serialChannels)
    {
        [ch close];
    }
    
    // Close all virtual screens
    for (VirtualScreenWindowController *vs in self.screens)
    {
        [vs close];
        [vs reset];
    }
    
    [self resetState:nil];
}

- (void)OP_RESYNC
{
	[statistics setObject:@"OP_RESYNC" forKey:@"OpCode"];
    [self postStatistics:statistics];
    [self resetState:nil];
}

- (void)OP_TIME
{
	time_t currentClock;
	struct tm *tpack;
	char os9tpack[6];
	
	time(&currentClock);
	tpack = localtime(&currentClock);
	os9tpack[0] = tpack->tm_year;
	os9tpack[1] = tpack->tm_mon + 1;
	os9tpack[2] = tpack->tm_mday;
	os9tpack[3] = tpack->tm_hour;
	os9tpack[4] = tpack->tm_min;
	os9tpack[5] = tpack->tm_sec;
//	os9tpack[6] = tpack->tm_wday;
	
	// Send time packet to CoCo
	[portDelegate writeData:[NSData dataWithBytes:os9tpack length:6]];
	
	// Update log
	[statistics setObject:@"OP_TIME" forKey:@"OpCode"];
    [self postStatistics:statistics];

    [self resetState:nil];
}

- (NSUInteger)OP_REREAD:(NSData *)data;
{
    return [self OP_READ:data];
}

- (NSUInteger)OP_REREADEX:(NSData *)data;
{
    return [self OP_READEX:data];
}

- (void)resetState:(NSTimer *)theTimer
{
    self.currentState = @selector(OP_OPCODE:);
    [self invalidateWatchdog];
}


#pragma mark -
#pragma mark Sector Read/Write Methods

- (NSUInteger)OP_READ:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 4)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 4 bytes (1 byte drive number, 3 byte LSN)
        result = 4;
        
		uint32_t driveNumber;
		NSData *sectorBuffer = nil;
		unsigned int vLSN;
		uint16_t myChecksum;
		unsigned char b[2], response;
		
		// Assume no error to CoCo for now.
		response = 0;
		
		// Extract drive number and LSN from data packet.
		driveNumber = bytes[0];
		vLSN = (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
		
		// Check drive number for veracity
		if (driveNumber >= [driveArray count])
		{
			response = 240;
		}
		else
		{
			// Read sector from disk image.
			sectorBuffer = [[driveArray objectAtIndex:driveNumber] readSectors:vLSN forCount:1];
			if (sectorBuffer == nil)
			{
				response = 246;		// E$NotRdy
			}
		}
		
		// Send the response code to the CoCo.
		[portDelegate writeData:[NSData dataWithBytes:&response length:1]];
		
		// If we have an OK response, we send the sector and Checksum.
		if (response == 0)
		{
			// Write sector to CoCo.
			if ([sectorBuffer bytes] != NULL)
			{
				// Send sector.
				[portDelegate writeData:sectorBuffer];
				
				// Compute Checksum from sector.
				if (self.validateWithCRC == NO)
				{
					myChecksum = [self compute16BitChecksum:[sectorBuffer bytes] length:256];
				}
				else
				{
					myChecksum = [self computeCRC:[sectorBuffer bytes] length:256];
				}
			}
			else
			{
				// If [sectorBuffer bytes] == NULL, then the DSK manager
				// read past the end of the file.  This is ok because
				// OS-9's view of the disk may be larger than the physical
				// file that holds the image.  We'll just send a fake
				// sector with zero bytes.
				
				u_char nullSector[256] =
				{
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
					0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
				};
                
				[portDelegate writeData:[NSData dataWithBytes:nullSector length:256]];
				
				// The Checksum will be zero.
				myChecksum = [self compute16BitChecksum:nullSector length:256];
			}
            
			// Send statistical data via notification
			[statistics setObject:NSStringFromSelector(self.currentState) forKey:@"OpCode"];
			[statistics setObject:[NSString stringWithFormat:@"%d", vLSN] forKey:@"LSN"];
			[statistics setObject:[NSString stringWithFormat:@"%d", driveNumber] forKey:@"DriveNumber"];
			
			// Kinda hackish -- we should get the "all" stats from the jukebox
            if (self.currentState == @selector(OP_REREAD:))
			{
				int32_t sectorsReRead = [[statistics objectForKey:@"ReReadCount"] intValue] + 1;
				
				[statistics setObject:[NSString stringWithFormat:@"%d", sectorsReRead] forKey:@"ReReadCount"];
			}
			else
			{
				int32_t sectorsRead = [[statistics objectForKey:@"ReadCount"] intValue] + 1;
				
				[statistics setObject:[NSString stringWithFormat:@"%d", sectorsRead] forKey:@"ReadCount"];
			}
			
			[statistics setObject:[NSString stringWithFormat:@"%d", response] forKey:@"Error"];
			[statistics setObject:[NSString stringWithFormat:@"%d", myChecksum] forKey:@"Checksum"];
            [self postStatistics:statistics];

			// Send Checksum on to CoCo
			b[0] = myChecksum >> 8;
			b[1] = myChecksum & 0xFF;
			[portDelegate writeData:[NSData dataWithBytes:b length:2]];
		}
		
		// Reset state
		[self resetState:nil];
	}
	
	return result;
}

- (NSUInteger)OP_READEX:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 4)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 4 bytes into this buffer (1 byte drive number, 3 byte LSN)
        result = 4;
        
        uint32_t driveNumber;
        NSData *sectorBuffer = nil;
        unsigned int vLSN;
		
        // Assume no error to CoCo for now.
        readexResponse = 0;
		
        // Extract drive number and LSN from data packet.
        driveNumber = bytes[0];
        vLSN = (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
		
		// Check drive number for veracity
		if (driveNumber >= [driveArray count])
		{
			readexResponse = 240;
		}
		else
		{
			// Read sector from disk image.
			sectorBuffer = [[driveArray objectAtIndex:driveNumber] readSectors:vLSN forCount:1];
			if (sectorBuffer == nil)
			{
				readexResponse = 246;		// E$NotRdy
			}
		}

        {
            // Write sector to CoCo.
            if (readexResponse == 0 && [sectorBuffer bytes] != NULL)
            {
                // Send sector.
                [portDelegate writeData:sectorBuffer];
				
                // Compute Checksum from sector.
               if (self.validateWithCRC == NO)
               {
                  readexChecksum = [self compute16BitChecksum:[sectorBuffer bytes] length:256];
               }
               else
               {
                  readexChecksum = [self computeCRC:[sectorBuffer bytes] length:256];
               }
            }
            else
            {
               BGPDebug(@"Writing zero bytes sector");
                // If [sectorBuffer bytes] == NULL, then the DSK manager
                // read past the end of the file.  This is ok because
                // OS-9's view of the disk may be larger than the physical
                // file that holds the image.  We'll just send a fake
                // sector with zero bytes.
                
                u_char nullSector[256] =
                {
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                };
                   
                [portDelegate writeData:[NSData dataWithBytes:nullSector length:256]];
               
                // The Checksum will be zero.
                readexChecksum = [self compute16BitChecksum:nullSector length:256];
            }
            
            // Send statistical data via notification
            [statistics setObject:NSStringFromSelector(self.currentState) forKey:@"OpCode"];
            [statistics setObject:[NSString stringWithFormat:@"%d", vLSN] forKey:@"LSN"];
            [statistics setObject:[NSString stringWithFormat:@"%d", driveNumber] forKey:@"DriveNumber"];

            // Kinda hackish -- we should get the "all" stats from the jukebox
            if (self.currentState == @selector(OP_REREADEX:))
            {
               int32_t sectorsReRead = [[statistics objectForKey:@"ReReadCount"] intValue] + 1;
               
               [statistics setObject:[NSString stringWithFormat:@"%d", sectorsReRead] forKey:@"ReReadCount"];
            }
            else
            {
               int32_t sectorsRead = [[statistics objectForKey:@"ReadCount"] intValue] + 1;
               
               [statistics setObject:[NSString stringWithFormat:@"%d", sectorsRead] forKey:@"ReadCount"];
            }

            [statistics setObject:[NSString stringWithFormat:@"%d", readexResponse] forKey:@"Error"];
            [statistics setObject:[NSString stringWithFormat:@"%d", readexChecksum] forKey:@"Checksum"];
            [self postStatistics:statistics];
        }

        if (0 == readexResponse)
        {
            self.currentState = @selector(OP_READEXP2:);
        }
        else
        {
            [self resetState:nil];
        }
    }
	
    return result;
}

- (NSUInteger)OP_READEXP2:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 2)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 2 bytes into this buffer (CoCo's checksum)
        // Here we're expecting the checksum from the CoCo
        result = 2;
        
        uint16_t cocoChecksum = 0;
      
        cocoChecksum = bytes[0] * 256 + bytes[1];
        if (readexChecksum != cocoChecksum)
        {
            readexResponse = E_CRC;
        }
      
        // Send the response code to the CoCo.
        [portDelegate writeData:[NSData dataWithBytes:&readexResponse length:1]];
      
	   [self resetState:nil];
   }
   
   return result;
}

- (NSUInteger)OP_REWRITE:(NSData *)data;
{
    return [self OP_WRITE:data];
}

- (NSUInteger)OP_WRITE:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 262)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read all 262 bytes into this buffer (1 byte drive number, 3 byte LSN, 256 byte sector, and 2 byte Checksum)
        result = 262;
        
        uint32_t vLSN;
        uint32_t driveNumber;
        uint16_t myChecksum = 0, cocoChecksum = 0;
        unsigned char response;

        // Extract drive number and LSN from data packet.
        driveNumber = bytes[0];
        vLSN = (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
        cocoChecksum = bytes[260] << 8 | bytes[261];

        // Check drive number for veracity
        if (driveNumber >= [driveArray count])
        {
            response = 240;
        }
        else
        {
            // Compute Checksum from sector.
            if (self.validateWithCRC == NO)
            {
                myChecksum = [self compute16BitChecksum:&bytes[4] length:256];
            }
            else
            {
                myChecksum = [self computeCRC:&bytes[4] length:256];
            }

            // Compare Checksums and send appropriate flag.
            if (cocoChecksum == myChecksum)
            {
                // Sector transferred OK.
                response = 0;
            
                // Check to see if cartridge is inserted, then write sector to disk image.
                if ([[driveArray objectAtIndex:driveNumber] isEmpty] == YES)
                {
                    response = 246;
                }
                else
                {
                    NSData *sector = [[NSData alloc ] initWithBytesNoCopy:(void *)&bytes[4] length:256 freeWhenDone:NO];
            
                    [[driveArray objectAtIndex:driveNumber] writeSectors:vLSN forCount:1 sectors:sector];
                }
            }
            else
            {
                // Sector didn't transfer ok - send E$CRC.
                response = E_CRC;
            }
        }

        // Send statistical data via notification
        if (response == 0)
        {
            [statistics setObject:NSStringFromSelector(self.currentState) forKey:@"OpCode"];
            [statistics setObject:[NSString stringWithFormat:@"%d", vLSN] forKey:@"LSN"];
            [statistics setObject:[NSString stringWithFormat:@"%d", driveNumber] forKey:@"DriveNumber"];

            // Kinda hackish -- we should get the "all" stats from the jukebox
            if (self.currentState == @selector(OP_REWRITE:))
            {
                int32_t sectorsWritten = [[statistics objectForKey:@"WriteCount"] intValue] + 1;
            
                [statistics setObject:[NSString stringWithFormat:@"%d", sectorsWritten] forKey:@"WriteCount"];
            }
            else
            {
                int32_t sectorsReWritten = [[statistics objectForKey:@"ReWriteCount"] intValue] + 1;
            
                [statistics setObject:[NSString stringWithFormat:@"%d", sectorsReWritten] forKey:@"ReWriteCount"];
            }

            [statistics setObject:[NSString stringWithFormat:@"%d", response] forKey:@"Error"];
            [statistics setObject:[NSString stringWithFormat:@"%d", myChecksum] forKey:@"Checksum"];
            [self postStatistics:statistics];
        }

        // Send response to CoCo.
        [portDelegate writeData:[NSData dataWithBytes:&response length:1]];

        // Reset state.
        [self resetState:nil];
    }

    return result;
}


#pragma mark -
#pragma mark GetStat/SetStat Methods

- (NSUInteger)OP_GETSTAT:(NSData *)data;
{
    return [self statCommon:@"GetStat" withData:data];
}

- (NSUInteger)OP_SETSTAT:(NSData *)data;
{
    return [self statCommon:@"SetStat" withData:data];
}

- (NSUInteger)statCommon:(NSString *)whichStat withData:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 2)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 2 bytes into this buffer (1 byte drive number, 1 getstat code)
        result = 2;

        uint32_t driveNumber, statCode;
		
        driveNumber = bytes[0];
		statCode = bytes[1];
		
		if (driveNumber < [driveArray count] && [[driveArray objectAtIndex:driveNumber] isEmpty] == NO)
		{
			// Send statistical data via notification
			[statistics setObject:NSStringFromSelector(self.currentState) forKey:@"OpCode"];
            [statistics setObject:[NSString stringWithFormat:@"%d", driveNumber] forKey:@"DriveNumber"];
			[statistics setObject:[self statCodeToString:statCode] forKey:whichStat];
            [self postStatistics:statistics];

			// Process specific stat codes (Version 3 and greater)
			if ([whichStat isEqualToString:@"SetStat"] == YES)
			{
				switch (statCode)
				{
					case 0x0C:	// SS.SQD
						// Eject the cartridge
						[[driveArray objectAtIndex:driveNumber] ejectCartridge:self];
						break;
				}
            }
        }
		
        // Reset state.
        [self resetState:nil];
    }
	
	return result;
}

- (NSString *)statCodeToString:(int)code
{
    NSString *statString;
    
    switch (code)
    {
        case 0x00:
            statString = @"SS.Opt";
            break;
            
        case 0x02:
            statString = @"SS.Size";
            break;
            
        case 0x03:
            statString = @"SS.Reset";
            break;
            
        case 0x04:
            statString = @"SS.WTrk";
            break;
            
        case 0x05:
            statString = @"SS.Pos";
            break;
            
        case 0x06:
            statString = @"SS.EOF";
            break;
            
        case 0x0A:
            statString = @"SS.Frz";
            break;
            
        case 0x0B:
            statString = @"SS.SPT";
            break;
            
        case 0x0C:
            statString = @"SS.SQD";
            break;
            
        case 0x0D:
            statString = @"SS.DCmd";
            break;
            
        case 0x0E:
            statString = @"SS.DevNm";
            break;
            
        case 0x0F:
            statString = @"SS.FD";
            break;
            
        case 0x10:
            statString = @"SS.Ticks";
            break;
            
        case 0x11:
            statString = @"SS.Lock";
            break;
            
        case 0x12:
            statString = @"SS.VarSect";
            break;
			
        case 0x13:
            statString = @"SS.Eject";
            break;
			
        case 0x14:
            statString = @"SS.BlkRd";
            break;
            
        case 0x15:
            statString = @"SS.BlkWr";
            break;
            
        case 0x16:
            statString = @"SS.Reten";
            break;
            
        case 0x17:
            statString = @"SS.WFM";
            break;
            
        case 0x18:
            statString = @"SS.RFM";
            break;
            
        case 0x1B:
            statString = @"SS.Relea";
            break;
            
        case 0x1C:
            statString = @"SS.Attr";
            break;
            
        case 0x1E:
            statString = @"SS.RsBit";
            break;
            
        case 0x20:
            statString = @"SS.FDInf";
            break;
            
        case 0x26:
            statString = @"SS.DSize";
            break;
            
        default:
            statString = [[NSString alloc] initWithFormat:@"%d", code];
            break;
    }
	
    return(statString);
}


#pragma mark -
#pragma mark Named Object Methods

- (NSUInteger)OP_NAMEOBJ_MOUNT:(NSData *)data;
{
    NSUInteger result = 1;
    
    u_char *bytes = (u_char *)[data bytes];
        
    nameobj_size = bytes[0];

    self.currentState = @selector(OP_NAMEOBJ_MOUNT_NAME:);
    
    return result;
}

- (NSUInteger)OP_NAMEOBJ_MOUNT_NAME:(NSData *)data;
{
    NSUInteger result = 0;
    
    if (nameobj_size > 0 && [data length] >= nameobj_size)
    {
        result = nameobj_size;
        
		[statistics setObject:@"OP_NAMEOBJ_MOUNT" forKey:@"OpCode"];
        [self postStatistics:statistics];

		// build the path to the named object
        NSData *namedObjectData = [data subdataWithRange:NSMakeRange(0, nameobj_size)];
        NSString *namedObject = [NSString stringWithCString:[namedObjectData bytes] encoding:NSUTF8StringEncoding];
        
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), namedObject];

		// go through existing drives to see if it already exists
		int i;
		for (i = 0; i < [driveArray count]; i++)
		{
			VirtualDriveController *c = [driveArray objectAtIndex:i];
			if ([[c cartridgePath] isEqualToString:fullPath])
			{
				break;
			}
		}
		
		if (i == [driveArray count])
		{
			VirtualDriveController *drive = [[VirtualDriveController alloc] init];
			[drive setDriveID:i];
			[drive insertCartridge:fullPath];
			[driveArray addObject:drive];
		}

		u_char b = (u_char)i;
		[portDelegate writeData:[NSData dataWithBytes:&b length:1]];

		// Reset the current location now that we've achieved it.
		[self resetState:nil];
	}
    
    return result;
}


#pragma mark -
#pragma mark Virtual Serial Methods

- (NSUInteger)OP_SERINIT:(NSData *)data;
{
    NSUInteger result = 1;
    
    u_char *bytes = (u_char *)[data bytes];
    
    if (*bytes > 16)
    {
        // Virtual Screen
        int channelNumber = *bytes;
        
        VirtualScreenWindowController *screen = [self screenWithNumber:channelNumber - 17];
        [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualScreenOpenedNotification
                                                            object:self
                                                          userInfo:@{@"screen" : screen}];
    }
    
    // Update log
    [statistics setObject:@"OP_SERINIT" forKey:@"OpCode"];
    [self postStatistics:statistics];

    [self resetState:nil];
    
    return result;
}

- (NSUInteger)OP_SERTERM:(NSData *)data;
{
    NSUInteger result = 1;
    
    u_char *bytes = (u_char *)[data bytes];
    
    if (*bytes > 16)
    {
        // Virtual Screen
        int channelNumber = *bytes;
        
        VirtualScreenWindowController *screen = [self screenWithNumber:channelNumber - 17];
        [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualScreenClosedNotification
                                                            object:self
                                                          userInfo:@{@"screen" : screen}];
    }
    
    // Update log
    [statistics setObject:@"OP_SERTERM" forKey:@"OpCode"];
    [self postStatistics:statistics];

    [self resetState:nil];
    
    return result;
}

- (NSUInteger)OP_SERGETSTAT:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 2)
    {
        //        u_char *bytes = (u_char *)[data bytes];
        
        // We read 2 bytes into this buffer (1 channel number, 1 getstat code)
        result = 2;
        
        // Update log
        [statistics setObject:@"OP_SERGETSTAT" forKey:@"OpCode"];
        [self postStatistics:statistics];

        [self resetState:nil];
    }
    
    return result;
}

- (NSUInteger)OP_SERSETSTAT_SS_COMST:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 26)
    {
        // We read 26 bytes of SS.ComSt data
        result = 26;
        
        // Update log
        [statistics setObject:@"OP_SERSETSTAT" forKey:@"OpCode"];
        [self postStatistics:statistics];

        [self resetState:nil];
    }
    
    return result;
}

- (NSUInteger)OP_SERSETSTAT:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 2)
    {
        // We read 2 bytes into this buffer (1 channel number, 1 setstat code)
        result = 2;
        
        u_char *bytes = (u_char *)[data bytes];
        
        u_char channelNumber = bytes[0];
        u_char statCode = bytes[1];
        
        switch (statCode)
        {
            case 0x1b: // SS.Relea
                break;

            case 0x28: // SS.ComSt
                // gotta read 26 more bytes for SS.ComSt
                self.currentState = @selector(OP_SERSETSTAT_SS_COMST:);
                return result;
                
            case 0x29: // SS.Open
                // open channel
            {
                if (channelNumber > 16)
                {
                    // Virtual Screen
                }
                else
                {
                    VirtualSerialChannel *channel = [self channelWithNumber:channelNumber];
                    [channel open];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelConnectedNotification
                                                                        object:self
                                                                      userInfo:@{@"channel" : channel}];
                }
                break;
            }

            case 0x2A: // SS.Close
                // close channel
            {
                if (channelNumber > 16)
                {
                    // Virtual Screen
                }
                else
                {
                    VirtualSerialChannel *channel = [self channelWithNumber:channelNumber];
                    [channel close];
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:kVirtualChannelDisconnectedNotification
                                                                    object:self
                                                                  userInfo:@{@"channel" : channel}];
                }
                break;
            }
        }

        // Update log
        [statistics setObject:@"OP_SERSETSTAT" forKey:@"OpCode"];
        [self postStatistics:statistics];

        [self resetState:nil];
    }
    
    return result;
}

- (void)OP_SERREAD;
{
    u_char response[2] = {0, 0};
    VirtualSerialChannel *channel = nil;
    VirtualScreenView *screen = nil;

    for (channel in self.serialChannels)
    {
        NSUInteger length = [channel availableToRead];
        if (length > 0)
        {
            if (length == 1)
            {
                response[0] = (u_char)([channel number]);
                response[1] = [channel getByte];
                channel.waitCounter = 0;
            }
            else
            {
                response[0] = (u_char)([channel number]) | 0x10;
                response[1] = length > 16 ? 16 : (u_int8_t)length;
                channel.waitCounter = 0;
            }
            break;
        }
        else
        {
            channel.waitCounter++;
            
            if (channel.shouldClose == TRUE)
            {
                channel.shouldClose = FALSE;
                response[0] = 0x10;
                response[1] = channel.number - 1;
            }
        }
    }
    
    for (VirtualScreenWindowController *windowController in self.screens)
    {
        screen = [[(VirtualScreenView *)windowController.window.contentView subviews] objectAtIndex:0];
        NSUInteger length = [screen availableToRead];
        if (length > 0)
        {
            if (length > 0)
            {
                response[0] = (u_char)(windowController.number) | 0x40;
                response[1] = [screen getByte];
                screen.waitCounter = 0;
            }
            else
            {
                response[0] = (u_char)(windowController.number) | 0x60;
                response[1] = length > 16 ? 16 : (u_int8_t)length;
                screen.waitCounter = 0;
            }
            break;
        }
        else
        {
            screen.waitCounter++;
            
            if (screen.shouldClose == TRUE)
            {
                screen.shouldClose = FALSE;
                response[0] = 0x60;
                response[1] = windowController.number;
            }
        }
    }
    
    [portDelegate writeData:[NSData dataWithBytes:response length:2]];
    
    // Update log
    [statistics setObject:@"OP_SERREAD" forKey:@"OpCode"];
    BGPDebug(@"->OP_SERREAD... [$%02X,$%02X]->", response[0], response[1]);
    [self postStatistics:statistics];

    [self resetState:nil];
}

- (NSUInteger)OP_SERWRITE:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 2)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 2 bytes into this buffer (1 byte drive number, 1 getstat code)
        result = 2;
        
        NSUInteger channelNumber = bytes[0] - 1;
        
        VirtualSerialChannel *channel = [self channelWithNumber:channelNumber];
        [channel putByte:bytes[1]];
    }
    
    // Update log
    [statistics setObject:@"OP_SERWRITE" forKey:@"OpCode"];
    [self postStatistics:statistics];

    [self resetState:nil];
    
    return result;
}

- (NSUInteger)OP_SERREADM:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 2)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 2 bytes into this buffer (channel number, bytes requested)
        result = 2;
        
        NSUInteger channelNumber = bytes[0];
        NSUInteger bytesToRead = bytes[1];
        
        VirtualSerialChannel *channel = [self channelWithNumber:channelNumber];
        NSData *dataToRead = [channel getNumberOfBytes:bytesToRead];

        [portDelegate writeData:dataToRead];
    
        // Update log
        [statistics setObject:@"OP_SERREADM" forKey:@"OpCode"];
        BGPDebug(@"->OP_SERREADM... [$%02X,$%02X]->", channelNumber, bytesToRead);
        [self postStatistics:statistics];

        [self resetState:nil];
    }
    
    return result;
}

- (NSUInteger)OP_SERWRITEM:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 2)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 2 bytes into this buffer (channel number, bytes following)
        result = 2;
        
        self.serwritemChannelNumber = bytes[0];
        self.serwritemBytesFollowing = bytes[1];
        
        self.currentState = @selector(OP_SERWRITEMP2:);
    }
    
    return result;
}

- (VirtualSerialChannel *)channelWithNumber:(u_int8_t)number;
{
    VirtualSerialChannel *result = nil;
    
    if (number < [self.serialChannels count])
    {
        result = [self.serialChannels objectAtIndex:number];
    }
    
    return result;
}

- (VirtualScreenWindowController *)screenWithNumber:(u_int8_t)number;
{
    VirtualScreenWindowController *result = nil;
    
    if (number < [self.screens count])
    {
        result = [self.screens objectAtIndex:number];
    }
    
    return result;
}

- (NSUInteger)OP_SERWRITEMP2:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= self.serwritemBytesFollowing)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 2 bytes into this buffer (channel number and data byte)
        result = self.serwritemBytesFollowing;
        
        NSUInteger channelNumber = self.serwritemChannelNumber;
        
        VirtualSerialChannel *channel = [self channelWithNumber:channelNumber];
        [channel putBytes:bytes length:result];
        
        // Update log
        [statistics setObject:@"OP_SERWRITE" forKey:@"OpCode"];
        BGPDebug(@"OP_SERWRITE[$%02X,%c]->", channelNumber, bytes);
        [self postStatistics:statistics];

        [self resetState:nil];
    }
    
    return result;
}

- (NSUInteger)OP_FASTWRITE:(NSData *)data;
{
    NSUInteger result = 0;
    
    u_char *bytes = (u_char *)[data bytes];
    
    // We read 1 bytes into this buffer (data byte)
    result = 1;
    
    VirtualSerialChannel *channel = [self channelWithNumber:self.fastwriteChannel];
    [channel putByte:bytes[0]];
    
    // Update log
    [statistics setObject:@"OP_FASTWRITE" forKey:@"OpCode"];
    [self postStatistics:statistics];
    BGPDebug(@"->OP_FASTWRITE[$%02X,$%02X(%c)]", self.fastwriteChannel + 0x7F, bytes[0], bytes[0] >=' ' ? bytes[0] : ' ');

    [self resetState:nil];

    return result;
}

- (NSUInteger)OP_FASTWRITE_VirtualScreen:(NSData *)data;
{
    NSUInteger result = 0;
    
    u_char *bytes = (u_char *)[data bytes];
    
    // We read 1 bytes into this buffer (data byte)
    result = 1;
    
    VirtualScreenWindowController *screen = [self screenWithNumber:self.fastwriteChannel];
    [screen putByte:bytes[0]];
    
    // Update log
    [statistics setObject:@"OP_FASTWRITE" forKey:@"OpCode"];
    [self postStatistics:statistics];
    BGPDebug(@"->OP_FASTWRITE[$%02X,$%02X(%c)]", self.fastwriteChannel, bytes[0], bytes[0] >=' ' ? bytes[0] : ' ');

    [self resetState:nil];
    
    return result;
}



#pragma mark -
#pragma mark WireBug Methods

- (NSUInteger)OP_WIREBUG_MODE:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 23)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 23 bytes into this buffer
        result = 23;
        
        [statistics setObject:@"OP_WIREBUG" forKey:@"OpCode"];
        [self postStatistics:statistics];

        wirebugCoCoType = bytes[0];
        wirebugCPUType = bytes[1];

		// Set WireBug state to TRUE
		[self setWirebugState:true];
		
		// Request registers
		[self readRegisters];
    }
    
    return result;
}

- (NSUInteger)OP_WIREBUG_READREGS_RESPONSE:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 24)
    {
        u_char *bytes = (u_char *)[data bytes];
        
        // We read 24 bytes into this buffer
        result = 24;
        
		uint8_t myChecksum = 0, targetChecksum = 0;
	
		// Extract Target's checksum.
		targetChecksum = bytes[24 - 1];
	
		// Compute Checksum from sector.
		myChecksum = [self compute8BitChecksum:&bytes[0] length:23];
	
		// Compare Checksums and send appropriate flag.
		if (targetChecksum == myChecksum)
		{
			if (bytes[0] == _OP_WIREBUG_READREGS)
			{
				_dp = bytes[1];
				_cc = bytes[2];
				_a  = bytes[3];
				_b  = bytes[4];
				_e  = bytes[5];
				_f  = bytes[6];
				_x  = bytes[7] << 8 | bytes[8];
				_y  = bytes[9] << 8 | bytes[10];
				_u  = bytes[11] << 8 | bytes[12];
				_md = bytes[13];
				_v  = bytes[14];
				_v  = bytes[15];
				_s  = bytes[16] << 8 | bytes[17];
				_pc = bytes[18] << 8 | bytes[19];

				[registers setObject:[NSNumber numberWithChar:_cc] forKey:@"CC"];
				[registers setObject:[NSNumber numberWithChar:_dp] forKey:@"DP"];
				[registers setObject:[NSNumber numberWithChar:_a]  forKey:@"A"];
				[registers setObject:[NSNumber numberWithChar:_b]  forKey:@"B"];
				[registers setObject:[NSNumber numberWithChar:_e]  forKey:@"E"];
				[registers setObject:[NSNumber numberWithChar:_f]  forKey:@"F"];
				[registers setObject:[NSNumber numberWithInt:_x]  forKey:@"X"];
				[registers setObject:[NSNumber numberWithInt:_y]  forKey:@"Y"];
				[registers setObject:[NSNumber numberWithInt:_u]  forKey:@"U"];
				[registers setObject:[NSNumber numberWithChar:_md]  forKey:@"MD"];
				[registers setObject:[NSNumber numberWithInt:_v]  forKey:@"V"];
				[registers setObject:[NSNumber numberWithInt:_s]  forKey:@"S"];
				[registers setObject:[NSNumber numberWithInt:_pc] forKey:@"PC"];
				
				// Extract registers and post notification
				[[NSNotificationCenter defaultCenter] postNotificationName:@"wirebugRegisters"
																	object:self
																  userInfo:registers];
            
            // Now ask for memory
            [self readMemoryFrom:0x0000 to:0x0100];
			}
			else
			{
				// bad response
			}
		}
		else
		{
		}
		
//		[self goCoCo:nil];
    }
    
    return result;
}

- (NSUInteger)OP_WIREBUG_WRITEREGS_RESPONSE:(NSData *)data;
{
    NSUInteger result = 0;
    
    [self resetState:nil];
    
    return result;
}

- (NSUInteger)OP_WIREBUG_READMEM_RESPONSE:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 24)
    {
//        u_char *bytes = (u_char *)[data bytes];
        
        // We read 24 bytes into this buffer
        result = 24;

        [self resetState:nil];
    }
    
    return result;
}

- (NSUInteger)OP_WIREBUG_WRITEMEM_RESPONSE:(NSData *)data;
{
    NSUInteger result = 0;
    
    [self resetState:nil];

    return result;
}

- (NSUInteger)OP_WIREBUG_GO_RESPONSE:(NSData *)data;
{
    NSUInteger result = 0;
    
    if ([data length] >= 24)
    {
//        u_char *bytes = (u_char *)[data bytes];
        
        // We read 24 bytes into this buffer
        result = 24;
        
	   [self resetState:nil];
    }
    
    return result;
}

- (void)readRegisters
{
	u_char requestBuffer[24];

    // Set state to capture remaining code
    self.currentState = @selector(OP_WIREBUG_READREGS_RESPONSE:);

	requestBuffer[0] = _OP_WIREBUG_READREGS;
	requestBuffer[23] = [self compute8BitChecksum:&requestBuffer[0] length:23];
	[portDelegate writeData:[NSData dataWithBytes:requestBuffer length:24]];
}

- (void)readMemoryFrom:(int)start to:(int)end;
{
	u_char requestBuffer[24];
   
    // Set state to capture remaining code
    self.currentState = @selector(OP_WIREBUG_READMEM_RESPONSE:);
   
	requestBuffer[0] = _OP_WIREBUG_READMEM;
    requestBuffer[1] = (start >> 8) & 0xFF;
    requestBuffer[2] = (start >> 0) & 0xFF;
    requestBuffer[2] = (char)19;
	requestBuffer[23] = [self compute8BitChecksum:&requestBuffer[0] length:23];
	[portDelegate writeData:[NSData dataWithBytes:requestBuffer length:24]];
}

- (void)goCoCo;
{
	u_char requestBuffer[24];

    // Set state to capture remaining code
    self.currentState = @selector(OP_WIREBUG_GO_RESPONSE:);

	requestBuffer[0] = _OP_WIREBUG_GO;
	requestBuffer[23] = [self compute8BitChecksum:&requestBuffer[0] length:23];
	[portDelegate writeData:[NSData dataWithBytes:requestBuffer length:24]];
	[self setWirebugState:false];
	[self resetState:nil];
}

#pragma mark -
#pragma mark VirtualSerialChannelDelegate Methods

- (void)sendRunTarget
{
	u_char msgOut[24];
	
	[statistics setObject:@"OP_WIREBUG_GO" forKey:@"OpCode"];
	msgOut[0] = _OP_WIREBUG_GO;
	[portDelegate writeData:[NSData dataWithBytes:msgOut length:24]];
	
    return;
}

- (void)didConnect:(VirtualSerialChannel *)channel;
{
    
}

- (void)didDisconnect:(VirtualSerialChannel *)channel;
{
    
}

- (void)didSendData:(VirtualSerialChannel *)channel;
{
    
}

- (void)didReceiveData:(VirtualSerialChannel *)channel;
{
    
}

#pragma mark -
#pragma mark AppleScript Support

- (NSScriptObjectSpecifier *)objectSpecifier;
{
    return [self.scriptingContainer objectSpecifierForModel:self];
}

- (void)handleInsertCommand:(NSScriptCommand *)command;
{
    NSUInteger driveNumber = [[command.arguments objectForKey:@"drive"] integerValue];
    NSURL *fileURL = [command.arguments objectForKey:@"fileURL"];
    NSString *file = [fileURL relativePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:file] == YES)
    {
        if (driveNumber < [self.driveArray count])
        {
            VirtualDriveController *drv = [self.driveArray objectAtIndex:driveNumber];
            [drv ejectCartridge:self];
            [drv insertCartridge:file];
        }
        else
        {
            [command setScriptErrorNumber:-9000];
            [command setScriptErrorString:@"Invalid drive number."];
        }
    }
    else
    {
        [command setScriptErrorNumber:-9001];
        [command setScriptErrorString:@"Disk image file doesn't exist."];
    }
}

- (void)handleEjectCommand:(NSScriptCommand *)command;
{
    NSUInteger driveNumber = [[command.arguments objectForKey:@"drive"] integerValue];
    if (driveNumber < [self.driveArray count])
    {
        VirtualDriveController *drv = [self.driveArray objectAtIndex:driveNumber];
        [drv ejectCartridge:self];
    }
    else
    {
        [command setScriptErrorNumber:-9000];
        [command setScriptErrorString:@"Invalid drive number."];
    }
}

- (void)handleReloadCommand:(NSScriptCommand *)command;
{
    NSUInteger driveNumber = [[command.arguments objectForKey:@"drive"] integerValue];
    if (driveNumber < [self.driveArray count])
    {
        VirtualDriveController *drv = [self.driveArray objectAtIndex:driveNumber];
        [drv resetCartridge:self];
    }
    else
    {
        [command setScriptErrorNumber:-9000];
        [command setScriptErrorString:@"Invalid drive number."];
    }
}

- (void)handleChangePortCommand:(NSScriptCommand *)command;
{
    NSString *portName = [command.arguments objectForKey:@"port"];

    if ([portName isEqualToString:@""])
    {
        [self setCommPort:@"No Device"];
    }

    else
    {
        BOOL result = [self setCommPort:portName];
        if (result == NO)
        {
            [command setScriptErrorNumber:-9002];
            [command setScriptErrorString:@"Serial port doesn't exist."];
        }
    }
}

@end
