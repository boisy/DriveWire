//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


#import "BGPLog.h"
#import "BGPSerialPort.h"
#import "NSError+BGP.h"

//#define DEBUG

NSString const *kBGPSerialPortBaudRate = @"BGPSerialPortBaudRate";
NSString const *kBGPSerialPortWordSize = @"BGPSerialPortWordSize";
NSString const *kBGPSerialPortParity = @"BGPSerialPortParity";
NSString const *kBGPSerialPortStopBits = @"BGPSerialPortStopBits";
NSString const *kBGPSerialPortMinimumReadBytes = @"BGPSerialPortMinimumReadBytes";
NSString const *kBGPSerialPortReadTimeout = @"BGPSerialPortReadTimeout";
NSString const *kBGPSerialPortCTSRTS = @"BGPSerialPortCTSRTS";
NSString const *kBGPSerialPortDTR = @"BGPSerialPortDTR";

@implementation BGPSerialPort

#pragma mark -
#pragma mark Init/Dealloc Methods

- (void)setPortUsingDictionary:(NSDictionary *)settingsDictionary;
{
	for (NSString *key in [settingsDictionary allKeys])
	{
		if (key == kBGPSerialPortBaudRate)
		{
			self.baudRate = [[settingsDictionary objectForKey:key] intValue];
		}
		else if (key == kBGPSerialPortWordSize)
		{
            self.wordSize = [[settingsDictionary objectForKey:key] intValue];
		}
		else if (key == kBGPSerialPortParity)
		{
			self.parity = [[settingsDictionary objectForKey:key] intValue];
		}
		else if (key == kBGPSerialPortStopBits)
		{
			self.stopBits = [[settingsDictionary objectForKey:key] intValue];
		}
		else if (key == kBGPSerialPortMinimumReadBytes)
		{
			self.minimumReadBytes = [[settingsDictionary objectForKey:key] intValue];
		}
		else if (key == kBGPSerialPortReadTimeout)
		{
			self.readTimeout = [[settingsDictionary objectForKey:key] intValue];
		}
		else if (key == kBGPSerialPortCTSRTS)
		{
			self.hardwareHandshaking = [[settingsDictionary objectForKey:key] boolValue];
		}
		else if (key == kBGPSerialPortDTR)
		{
			self.dtrState = [[settingsDictionary objectForKey:key] boolValue];
		}
	}
}

- (void)setPortDefaults;
{
	self.baudRate = 9600;
	self.wordSize = 8;
	self.parity = BGPSerialPortParityNone;
	self.stopBits = 1;
	self.minimumReadBytes = 0;
	self.readTimeout = 1;
	self.hardwareHandshaking = TRUE;
	self.dtrState = TRUE;
}

- (id)initWithCoder:(NSCoder *)coder;
{
	if (self = [super init])
	{
		self.deviceName = [coder decodeObjectForKey:@"deviceName"];
		self.serviceName = [coder decodeObjectForKey:@"serviceName"];
		self.baudRate = [coder decodeIntForKey:@"baudRate"];
		if (self.baudRate == 0)
		{
			[self setPortDefaults];
		}
		else
		{
			self.wordSize = [coder decodeIntForKey:@"wordSize"];
			self.parity = [coder decodeIntForKey:@"parity"];
			self.stopBits = [coder decodeIntForKey:@"stopBits"];
			self.readTimeout = [coder decodeIntForKey:@"readTimeout"];
			self.minimumReadBytes = [coder decodeIntForKey:@"minimumReadBytes"];
			self.hardwareHandshaking = [coder decodeBoolForKey:@"hardwareHandshaking"];
			self.dtrState = [coder decodeBoolForKey:@"dtrState"];
		}
		
		// set port defaults if baudRate is 0
		
		_threadCondition = [[NSCondition alloc] init];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:self.deviceName forKey:@"deviceName"];
    [coder encodeObject:self.serviceName forKey:@"serviceName"];
    [coder encodeInteger:_baudRate forKey:@"baudRate"];
    [coder encodeInt:_wordSize forKey:@"wordSize"];
    [coder encodeInt:_parity forKey:@"parity"];
    [coder encodeInt:_stopBits forKey:@"stopBits"];
    [coder encodeInt:_readTimeout forKey:@"readTimeout"];
    [coder encodeInt:_minimumReadBytes forKey:@"minimumReadBytes"];
    [coder encodeBool:_hardwareHandshaking forKey:@"hardwareHandshaking"];
    [coder encodeBool:_dtrState forKey:@"dtrState"];
}

- (id)initWithDeviceName:(NSString *)deviceName serviceName:(NSString *)serviceName;
{
    // Initialize our super.
    if ((self = [super init]))
    {
        self.fd = -1;
		self.owner = nil;
		self.deviceName = deviceName;
		self.serviceName = serviceName;
		[self setPortDefaults];
//		_threadCondition = [[NSCondition alloc] init];
    }

    // Return ourself.    
    return(self);
}

- (void)dealloc;
{
    self.delegate = nil;
	
	[self closePort];
	
	// Release retained variables
	_threadCondition = nil;
	self.deviceName = nil;
	self.serviceName = nil;
}

#pragma mark -
#pragma mark Port Acquisition Methods

- (void)startListenerThread;
{
	if (self.listenerThreadActive == FALSE)
	{
		// spin off listener thread.				
		[NSThread detachNewThreadSelector:@selector(listener2:) toTarget:self withObject:nil];
	}
}

- (void)stopListenerThread;
{
	if (self.listenerThreadActive == TRUE)
	{
		// Flag listener thread to quit
		self.listenerThreadActive = FALSE;
		
		// Wait for condition lock to indicate thread has shut down
		[_threadCondition wait];
	}
}

- (BOOL)openPort:(id)owner error:(NSError **)error;
{
    int status = -1;
	NSError *errorResult = nil;
	
	// if the port is already opened, return NO
	if (self.fd != -1)
	{
		errorResult = [NSError serialPortAlreadyOpen];
	}
	else
	{
		// acquire the path to the device.  If error, return an error.
		status = open([self.deviceName cStringUsingEncoding:NSASCIIStringEncoding], O_RDWR | O_NOCTTY | O_NDELAY);
		self.fd = status;

		if (status != -1) 
		{
			self.owner = owner;
			
			// set blocking I/O, no signal on data ready...
			if ((status = fcntl(self.fd, F_SETFL, 0)) != -1)
			{
                // Get the current options and save them for later reset.
				if ((status = tcgetattr(self.fd, &_originalTTYAttrs)) != -1)
				{
					// These options are documented in the man page for termios.
					_ttyAttrs = _originalTTYAttrs;
                    
					cfmakeraw(&_ttyAttrs);
					_ttyAttrs.c_cflag |= CLOCAL | CREAD;
					_ttyAttrs.c_lflag = IGNBRK | IGNPAR;

					//  baud rate
					status = cfsetspeed(&_ttyAttrs, self.baudRate);

					// word size
					switch (self.wordSize)
					{
						case 8:
							_ttyAttrs.c_cflag &= ~CSIZE;
							_ttyAttrs.c_cflag |= CS8;
							break;
							
						case 7:
							_ttyAttrs.c_cflag &= ~CSIZE;
							_ttyAttrs.c_cflag |= CS7;
							break;
							
						case 6:
							_ttyAttrs.c_cflag &= ~CSIZE;
							_ttyAttrs.c_cflag |= CS6;
							break;
							
						case 5:
							_ttyAttrs.c_cflag &= ~CSIZE;
							_ttyAttrs.c_cflag |= CS5;
							break;
					}
					
					// parity
                    switch (self.parity)
					{
						case BGPSerialPortParityNone:
							_ttyAttrs.c_cflag &= ~(PARENB | PARODD);
							break;
							
						case BGPSerialPortParityOdd:
							_ttyAttrs.c_cflag |= (PARENB | PARODD);
							break;
							
						case BGPSerialPortParityEven:
							_ttyAttrs.c_cflag |= PARENB;
							_ttyAttrs.c_cflag &= ~PARODD;
							break;
					}
					
					// stop bits
					switch (self.stopBits)
					{
						case 1:
							_ttyAttrs.c_cflag &= ~CSTOPB;
							break;
							
						case 2:
							_ttyAttrs.c_cflag |= CSTOPB;
							break;
					}

					// hardware handshaking
                    if (self.hardwareHandshaking == TRUE) {
                        _ttyAttrs.c_cflag |= CRTSCTS;
                    } else {
                        _ttyAttrs.c_cflag &= ~CRTSCTS;
					}

					// read timeout
					_ttyAttrs.c_cc[VTIME] = self.readTimeout;

					// minimum read bytes
					_ttyAttrs.c_cc[VMIN] = self.minimumReadBytes;

                    // set the options.
					status = tcsetattr(self.fd, TCSANOW, &_ttyAttrs);

                    if (status != -1)
                    {
                        // set the DTR state
                        int portstatus;
                        status = ioctl(self.fd, TIOCMGET, &portstatus);   // get current port status
                        if (status != -1)
                        {
                            if (self.dtrState == TRUE) {
                                portstatus |= TIOCM_DTR;
                            } else {
                                portstatus &= ~TIOCM_DTR;
                            }
                            
                            status = ioctl(self.fd, TIOCMSET, &portstatus);   // set current port status
                            if (status != -1)
                            {
                                // Log the opening of the port
                                BGPLogDebug(@"Opened port %@ @ %lu bps", self.serviceName, (unsigned long)self.baudRate);
                                [self startListenerThread];
                            }
                        }
                    }
				}
			}
		}

		if (status == -1)
		{
            NSString *message = nil;
            
            switch (errno)
            {
                case EINVAL:
                    message = @"An invalid argument was supplied.";
                    break;

                case EBUSY:
                    message = @"The device is busy. Ensure that no other process has the device open.";
                    break;
                    
                default:
                    message = [NSString stringWithFormat:@"Error %d.", errno];
                    break;
            }
            
            errorResult = [NSError serialPortFailedToOpen:message];
		}
	}

	if (error != nil)
	{
		*error = errorResult;
	}

	return errorResult == nil;
}

- (BOOL)closePort;
{
	BOOL result = YES;
	
	[self stopListenerThread];
	
	if (self.fd != -1)
	{
		close(self.fd);
		self.fd = -1;
		BGPLogDebug(@"Closed port %@", self.serviceName);
	}
	else
	{
		result = NO;
	}
	
	return result;
}


#pragma mark -
#pragma mark Data Acquisition Methods

// This method should run on its own thread.  It listens to any data coming in from the port,
// then packages that data and sends it out.
- (void)listener2:(id)anObject;
{
	if (self.fd == -1)
	{
		BGPLogDebug(@"BGPSerialPort Thread Error: self.fd = -1");
		return;
	}
	
	self.listenerThreadActive = TRUE;
	
    @autoreleasepool {
        BGPLogDebug(@"Entering BGPSerialPort Thread...");

        [[NSThread currentThread] setName:[self className]];
        
        // Do processing so long as we are allowed to run.
        while (self.listenerThreadActive == TRUE)
        {
            @autoreleasepool {
                NSData *readData = [self readData];
                
                if (readData != nil && [self.delegate respondsToSelector:@selector(serialPort:didReceiveData:)])
                {
                    [self.delegate serialPort:self didReceiveData:readData];
                }
            }
        }
        
        BGPLogDebug(@"Exiting BGPSerialPort Thread...");

        [_threadCondition signal];
    }
}

- (NSData *)readData;
{
	NSData *result = nil;
	struct timeval timeout;
	int selectResult = 0;
	fd_set localReadFDSet;

    // only if we have a valid port open
    if (self.fd != -1)
    {
		FD_ZERO(&localReadFDSet);
		FD_SET(self.fd, &localReadFDSet);
		
		timeout.tv_sec = 0;
		timeout.tv_usec = 100000; // check to see if port closed every 100ms

		selectResult = select(self.fd + 1, &localReadFDSet, NULL, NULL, &timeout);
		if (selectResult > 0 && FD_ISSET(self.fd, &localReadFDSet))
		{
			// get the number of available bytes
			ssize_t bytesAvailable = 0;
			
			ioctl(self.fd, FIONREAD, &bytesAvailable);
			
			// if there are bytes to read...
			if (bytesAvailable > 0)
			{
				// data is available, so malloc space and read the bytes in
				char *buf = malloc(bytesAvailable);
				bytesAvailable = read(self.fd, buf, bytesAvailable);
				
				if (bytesAvailable > 0)
				{
					// assuming a sane read, create an NSData object to take ownership of the buffer
					result = [NSData dataWithBytesNoCopy:buf length:bytesAvailable];
					if (self.logIncomingBytes == TRUE)
					{
						BGPLogDebug(@"%@ -> %@", self.serviceName, [result description]);
					}            
				}
				else
				{
					// catch the case where read() returned 0 or less... free the malloc'ed buffer
					free(buf);
				}
			}
		}
	}	
		
    return result;
}

- (NSData *)readNumberOfBytes:(NSUInteger)byteCount;
{
	NSMutableData *result = [NSMutableData data];
	
	while ([result length] < byteCount)
	{
		NSData *readData = [self readData];
		if (readData != nil)
		{
			[result appendData:readData];
		}
	}
	
    return result;
}

- (BOOL)writeData:(NSData *)data;
{
    BOOL result = FALSE;
    
    if (self.fd != -1)
    {
		ssize_t status = write(self.fd, [data bytes], [data length]);
        
        if (status != -1)
        {
            // write succeeded
            result = YES;
            
            if (self.logOutgoingBytes == TRUE)
            {
				BGPLogDebug(@"%@ -> %@", [data description], self.serviceName);
            }            
        }
    }
    
    return result;
}

- (BOOL)writeString:(NSString *)data;
{
    NSData *packaged = [data dataUsingEncoding:NSUTF8StringEncoding];

    return [self writeData:packaged];
}


#pragma mark -
#pragma mark Data Query Methods

- (BOOL)isOpen;
{
    if (self.fd == -1)
    {
        return NO;
    }
    
    return YES;
}


#pragma mark -
#pragma mark Port Control Methods

- (NSString *)description;
{
	return [NSString stringWithFormat:@"Service name = %@, device name = %@, baudRate = %ld", self.serviceName, self.deviceName, _baudRate];
}

@end
