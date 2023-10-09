//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2007 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


#import "BGPSerialManager.h"
#import <IOKit/serial/IOSerialKeys.h>
#import "NSError+BGP.h"

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>
#include <sys/param.h>
#include <sysexits.h>
#include <pthread.h>

@interface BGPSerialManager ()

+ (NSMutableDictionary *)allPorts;

@end

@implementation BGPSerialManager

static BGPSerialManager *_globalManager = nil;

+ (BGPSerialManager *)defaultManager;
{
	if (_globalManager == nil)
	{
		_globalManager = [BGPSerialManager new];
	}
	
	return _globalManager;
}

- (id)init;
{
    if ((self = [super init]))
    {
		NSMutableDictionary	*portsISee;
		NSEnumerator *oEnumerator, *kEnumerator;
		NSString *oValue, *kValue;
        
		// allocate space for port dictionary
		portList = [[NSMutableDictionary alloc] init];
		
		// get an dictionary of all ports and their device names.
        portsISee = [BGPSerialManager allPorts];

		oEnumerator = [portsISee objectEnumerator];
		kEnumerator = [portsISee keyEnumerator];

		// sift through each port and create a BGPSerialPort
		while ((kValue = [kEnumerator nextObject]))
		{
			BGPSerialPort *port;
			
			oValue = [oEnumerator nextObject];

#ifndef NDEBUG
            BGPLogDebug(@"Device name '%@' for port '%@'", oValue, kValue);
#endif

			port = [[BGPSerialPort alloc] initWithDeviceName:oValue serviceName:kValue];
			[portList setValue:port forKey:kValue];
		}
	}
        
    return self;
}

- (void)dealloc;
{
	NSEnumerator *e = [portList objectEnumerator];
	BGPSerialPort *p;
	
	while (p = [e nextObject])
	{
		[p closePort];
	}
}

- (NSMutableDictionary *)availablePorts;
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	for (NSString *portName in [portList allKeys])
	{
		BGPSerialPort *port = [portList objectForKey:portName];
		
		if (port.owner == nil)
		{
			[result setObject:port forKey:portName];
		}
	}
	
	return result;
}


#pragma mark -
#pragma mark Query methods

- (BOOL)doesPortExist:(NSString *)name;
{
	if ([portList objectForKey:name] != nil)
	{
		return YES;
	}
	
    return NO;
}

- (BOOL)isPortAvailable:(NSString *)name;
{
	BGPSerialPort *port = [portList objectForKey:name];
	
	if ([port owner] == nil)
	{
		return YES;
	}
	
	return NO;
}


#pragma mark -
#pragma mark Action methods

- (BGPSerialPort *)reservePort:(NSString *)name forOwner:(id)object error:(NSError **)error;
{
	NSError *result = nil;
	
#ifndef NDEBUG
	BGPLogDebug(@"Searching for %@ in %@", name, [portList allKeys]);
#endif
	
	BGPSerialPort *port = [portList objectForKey:name];
	
	if (port == nil)
	{
		result = [NSError serialPortNonExistent];
	}
	else
	{
		if (port.owner == nil)
		{
			// success! the owner is nil so we can reserve the port!
			port.owner = object;
		}
		else
		{
			port = nil;
			result = [NSError serialPortAlreadyReserved];
		}
	}
		
	if (error != nil)
	{
		*error = result;
	}
	
	return port;
}

- (BOOL)releasePort:(NSString *)name;
{
	BGPSerialPort *port = [portList objectForKey:name];
	
	if (port != nil)
	{
		port.owner = nil;
		
		return [port closePort];
	}
	
	return NO;
}

- (NSString *)findPortThatRespondsWith:(NSData *)response
							 toMessage:(NSData *)message 
						  withBaudRate:(NSUInteger)baudRate
					withinTimeInterval:(NSTimeInterval)timeInterval;
{
	NSString *result = nil;
	
	for (NSString *key in portList)
	{
		NSError *error = nil;
		
		BGPSerialPort *port = [portList objectForKey:key];
		if ([port isOpen] == NO)
		{
			[port openPort:self error:&error];
			
			if (nil == error)
			{
				[port setBaudRate:baudRate];
				[port writeData:message];
				
				NSData *incoming = nil;
				NSUInteger count = 0;
				
				do
				{
					incoming = [port readData];
					count++;
					EnforceDelay(0.1);
				} while (incoming == nil && count < timeInterval);
				
				[port closePort];

				if (nil != incoming && [incoming isEqualToData:response])
				{
					result = key;
					break;
				}
			}
		}
	}
	
	return result;
}

// The rest of this file contains methods and functions that should be internal to this class.

static kern_return_t MyFindSerialPorts(io_iterator_t *matchingServices, mach_port_t *masterPort);

+ (NSMutableDictionary *)allPorts;
{
    int		count = 0;
    mach_port_t masterPort = (mach_port_t)0x0;
    kern_return_t kernResult;
    NSMutableDictionary *names;
	
    // init the arrays.
    names = [[NSMutableDictionary alloc] init];
    io_iterator_t serialPortIterator = 0;
    kernResult = MyFindSerialPorts(&serialPortIterator, &masterPort);
    if  (kernResult == kIOReturnSuccess)
    {
        io_object_t		rs232Service;
		
        while ((rs232Service = IOIteratorNext(serialPortIterator)))
        {
            CFTypeRef	bsdPathAsCFString, serviceNameAsCFString;
			
            count++;            
            serviceNameAsCFString = IORegistryEntryCreateCFProperty
            (
			 rs232Service,
			 CFSTR(kIOTTYBaseNameKey),
			 kCFAllocatorDefault,
			 0
			 );
			
            bsdPathAsCFString = IORegistryEntryCreateCFProperty
			(
			 rs232Service,
			 CFSTR(kIOCalloutDeviceKey),
			 kCFAllocatorDefault,
			 0
			 );
			
            if (!([(__bridge NSString *)serviceNameAsCFString isEqualToString:@"Bluetooth-PDA-Sync"] || [(__bridge NSString *)serviceNameAsCFString isEqualToString:@"Bluetooth-Modem"]))
            {
#ifndef NDEBUG
                BGPLogDebug(@"[names setValue:%@ forKey:%@]", bsdPathAsCFString, serviceNameAsCFString);
#endif
     
// SiLabs forced our hand: http://www.perceptiveautomation.com/userforum/viewtopic.php?f=5&t=10085&p=71757#p71757
#ifdef THE_OLD_CRAPPY_WAY
                [names setValue:(NSString *)bsdPathAsCFString forKey:(NSString *)serviceNameAsCFString];
#else
                // New service name... take /dev/cu.XXXXXX and stip off the /dev/cu. to make the new service name.
                if ([(__bridge NSString *)bsdPathAsCFString hasPrefix:@"/dev/cu."])
                {
                    NSString *newServiceName = [(__bridge NSString *)bsdPathAsCFString substringFromIndex:8];
                    [names setValue:(__bridge NSString *)bsdPathAsCFString forKey:(NSString *)newServiceName];
                }
#endif
            }
             
            CFRelease(bsdPathAsCFString);
            CFRelease(serviceNameAsCFString);
			
            IOObjectRelease(rs232Service);
        }
	}
	
    IOObjectRelease(serialPortIterator);
    
    return names;
}

static kern_return_t MyFindSerialPorts(io_iterator_t *matchingServices, mach_port_t *masterPort)
{
    kern_return_t kernResult; 
    CFMutableDictionaryRef classesToMatch = NULL;

    *matchingServices = 0;
    kernResult = IOMasterPort(0, masterPort);
    if (kernResult != KERN_SUCCESS)
    {
#ifndef NDEBUG
        BGPLogDebug(@"IOMasterPort returned %d", kernResult);
#endif
        
        return kernResult;
    }
    
    // the provider class for serial devices is IOSerialBSDClient.
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);

    if (classesToMatch == NULL)
    {
#ifndef NDEBUG
        BGPLogDebug(@"IOServiceMatching returned a NULL dictionary.");
#endif

        return EX_UNAVAILABLE;
    }
    else
    { 
        CFDictionarySetValue
        (
            classesToMatch,
            CFSTR(kIOSerialBSDTypeKey),
            CFSTR(kIOSerialBSDAllTypes)
//            CFSTR(kIOSerialBSDRS232Type)
        );
    }
    
    kernResult = IOServiceGetMatchingServices
    (
        *masterPort,
        classesToMatch,
        matchingServices
    );

    if ((kernResult != KERN_SUCCESS) || (*matchingServices == 0))
    {
        if (kernResult == KERN_SUCCESS)
        {
            kernResult = EX_UNAVAILABLE; // Make sure error if no serial ports.
        }
    }
    
    return kernResult;
}

- (NSString *)description;
{
	return [portList description];
}

@end
