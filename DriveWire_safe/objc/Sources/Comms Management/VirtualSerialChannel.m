//
//  VirtualSerialChannel.m
//  DriveWire
//
//  Created by Boisy Pitre on 4/15/15.
//
//

#import "VirtualSerialChannel.h"
#import "VirtualSerialChannel+DWCommands.h"
#import "VirtualSerialChannel+TCPCommands.h"
#import "VirtualSerialChannel+ATCommands.h"
#import "GCDAsyncSocket.h"
#import "NSString+DriveWire.h"

NSString *const kVirtualChannelConnectedNotification = @"com.drivewire.VirtualChannelConnectedNotification";
NSString *const kVirtualChannelDisconnectedNotification = @"com.drivewire.VirtualChannelDisconnectedNotification";
NSString *const kVirtualChannelDataSentNotification = @"com.drivewire.VirtualChannelDataSentNotification";
NSString *const kVirtualChannelDataReceivedNotification = @"com.drivewire.VirtualChannelDataReceivedNotification";
NSString *const kVirtualChannelInsertDiskNotification = @"com.drivewire.VirtualChannelInsertDiskNotification";
NSString *const kVirtualChannelEjectDiskNotification = @"com.drivewire.VirtualChannelEjectDiskNotification";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@interface NSData (RemoveCRLF)

- (NSData *)dataWithoutLineFeeds;

@end

@implementation NSData (RemoveCRLF)

- (NSData *)dataWithoutLineFeeds;
{
    NSMutableData *result = [NSMutableData data];
    
    const char *bytes = [self bytes];
    for (int i = 0; i < [self length]; i++)
    {
        if (bytes[i] != '\x0A')
        {
            [result appendBytes:bytes + i length:1];
        }
    }
    
    return result;
}

@end


@implementation GlobalChannelArray

+ (NSMutableArray *)sharedArray;
{
    static NSMutableArray *sharedGlobalChannelArray = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedGlobalChannelArray = [[NSMutableArray alloc] init];
    });
    return sharedGlobalChannelArray;
}


@end

@implementation VirtualSerialChannel

#pragma mark -
#pragma mark GCDAsyncSocket Delegate Methods

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag;
{
    switch (tag)
    {
        case READTAG_DATA_READ:
            if (self.telnetMode == TRUE || 1 == 1)
            {
                // be wary of the CRLF followed by <NUL>
                data = [data dataWithoutLineFeeds];
            }
            [self.incomingBuffer appendData:data];
            [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelDataReceivedNotification
                                                                object:self.model
                                                              userInfo:@{@"channel" : self}];
            [sender readDataWithTimeout:READ_TIMEOUT tag:READTAG_DATA_READ];
            break;

        case READTAG_TELNET_COMMAND_RESPONSES_READ:
            [sender readDataWithTimeout:READ_TIMEOUT tag:READTAG_DATA_READ];
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sender didWriteDataWithTag:(long)tag;
{
    switch (tag)
    {
        case WRITETAG_DATA_WRITTEN:
            self.outgoingBuffer.length = 0;
            [sender readDataWithTimeout:READ_TIMEOUT tag:READTAG_DATA_READ];
            break;
            
        case WRITETAG_TELNET_COMMANDS_WRITTEN:
            [sender readDataToLength:[self.telnetCommands length] withTimeout:-1 tag:READTAG_TELNET_COMMAND_RESPONSES_READ];
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket;
{
    // ask telnet to turn off echo
    if (self.telnetMode == TRUE)
    {
//        [newSocket writeData:self.telnetCommands withTimeout:-1 tag:WRITETAG_TELNET_COMMANDS_WRITTEN];
    }

//    [newSocket writeData:self.outgoingBuffer withTimeout:WRITE_TIMEOUT tag:WRITETAG_DATA_WRITTEN];
    [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelConnectedNotification
                                                        object:self.model
                                                      userInfo:@{@"channel" : self}];
    self.mode = VMODE_TCP_SERVER;
    [[GlobalChannelArray sharedArray] addObject:newSocket];

    // announce new connection
    NSUInteger i = [[GlobalChannelArray sharedArray] indexOfObject:newSocket];
    NSString *announce = [NSString stringWithFormat:@"%lu %d\x0D", (unsigned long)i, newSocket.localPort];
    NSData *data = [announce dataUsingEncoding:NSASCIIStringEncoding];
    [self.incomingBuffer appendData:data];
    [sender readDataWithTimeout:READ_TIMEOUT tag:READTAG_DATA_READ];
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port;
{
    NSData *data = [@"SUCCESS\x0D"
                    dataUsingEncoding:NSASCIIStringEncoding];
    [self.incomingBuffer appendData:data];
    self.mode = VMODE_TCP_CLIENT;
    [sock readDataWithTimeout:READ_TIMEOUT tag:READTAG_DATA_READ];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    self.mode = VMODE_COMMAND;
    if (err != nil && err.code != GCDAsyncSocketNoError && err.code != GCDAsyncSocketClosedError)
    {
        NSData *data = [@"FAIL 240\x0D"
                    dataUsingEncoding:NSASCIIStringEncoding];
        [self.incomingBuffer appendData:data];
    }
}

#pragma mark -
#pragma mark Virtual Port Management Methods

- (void)open;
{
    self.waitCounter = 0;
    self.incomingBuffer = [NSMutableData data];
    self.outgoingBuffer = [NSMutableData data];
    
    self.mode = VMODE_COMMAND;
    [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelConnectedNotification
                                                        object:self
                                                      userInfo:@{@"channel" : self}];
}

- (void)close;
{
    self.incomingBuffer = nil;
    self.outgoingBuffer = nil;
    
    for (GCDAsyncSocket *sock in self.listenSockets)
    {
        [sock disconnect];
    }
    
    if ([[GlobalChannelArray sharedArray] containsObject:self.serverSocket])
    {
        NSUInteger connectionNumber = [[GlobalChannelArray sharedArray] indexOfObject:self.serverSocket];
        [[GlobalChannelArray sharedArray] replaceObjectAtIndex:connectionNumber withObject:[NSNull null]];
    }

    [self.serverSocket disconnect];
    self.serverSocket = nil;

    [self.clientSocket disconnect];
    [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelDisconnectedNotification
                                                        object:self.model
                                                      userInfo:@{@"channel" : self}];
}

- (BOOL)hasData;
{
    return [self.incomingBuffer length] > 0;
}

- (NSUInteger)availableToRead;
{
    return [self.incomingBuffer length];
}

- (u_char)getByte;
{
    u_char result = 0;
    
    if ([self hasData])
    {
        result = *(u_char *)[self.incomingBuffer bytes];
        [self.incomingBuffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:nil length:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelDataReceivedNotification
                                                            object:self.model
                                                          userInfo:@{@"channel" : self}];
    }
    
    return result;
}

- (NSData *)getNumberOfBytes:(NSUInteger)count;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelDataReceivedNotification
                                                        object:self.model
                                                      userInfo:@{@"channel" : self}];
    NSData *result = nil;
    NSUInteger available = [self availableToRead];
    if (count > available)
    {
        count = available;
    }
    
    // get data directly from channel's incoming buffer
    result = [self.incomingBuffer subdataWithRange:NSMakeRange(0, count)];
    [self.incomingBuffer replaceBytesInRange:NSMakeRange(0, count) withBytes:nil length:0];
    
    return result;
}

- (void)putByte:(u_char)byte;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVirtualChannelDataSentNotification
                                                        object:self.model
                                                      userInfo:@{@"channel" : self}];
    switch (self.mode)
    {
        case VMODE_COMMAND:
            if (byte == '\x0D')
            {
                // we have a complete command -- parse it
                [self parseTopLevelCommand:self.outgoingBuffer];
                [self.outgoingBuffer setLength:0];
            }
            else
            {
                [self.outgoingBuffer appendBytes:&byte length:1];
            }
            break;
            
        case VMODE_TCP_CLIENT:
        case VMODE_PASSTHRU:
        {
            NSData *d = [NSData dataWithBytes:&byte length:1];
//            [self.outgoingBuffer appendBytes:&byte length:1];
            [self.serverSocket writeData:d withTimeout:WRITE_TIMEOUT tag:WRITETAG_DATA_WRITTEN];
            break;
        }
            
        case VMODE_TCP_SERVER:
            if (byte == '\x0D')
            {
                // we have a complete command -- parse it
                [self parseTopLevelCommand:self.outgoingBuffer];
                [self.outgoingBuffer setLength:0];
            }
            else
            {
                [self.outgoingBuffer appendBytes:&byte length:1];
            }
            break;
    }
}

- (void)putBytes:(u_char *)bytes length:(NSUInteger)length;
{
    for (int i = 0; i < length; i++)
    {
        [self putByte:bytes[i]];
    }
}


#pragma mark -
#pragma mark Top Level Command Handler

// parse the string data represented by the passed NSData buffer
- (NSError *)parseTopLevelCommand:(NSData *)buffer;
{
    NSError *error = nil;
    
    NSString *string = [[[NSString alloc] initWithData:buffer encoding:NSASCIIStringEncoding] lowercaseString];
    string = [string stringByProcessingBackspaces];
    
    NSArray *array = [[string stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@" "];
    
    // setup command array
    NSDictionary *commandDictionary = @{@"tcp" : @"handleTCPCommand:",
                                        @"dw"  : @"handleDWCommand:"
                               };

    if ([array count] > 0)
    {
        NSString *command = [array objectAtIndex:0];
        NSString *selectorString = [commandDictionary objectForKey:command];
        if (nil != selectorString)
        {
            SEL selector = NSSelectorFromString(selectorString);
            error = [self performSelector:selector withObject:array];
        }
        else
        {
            command = [array objectAtIndex:0];
            if ([command length] >=2 && [[command substringToIndex:2] isEqualToString:@"at"])
            {
                [self handleATCommand:array];
            }
        }
    }
    
    return error;
}


#pragma mark -
#pragma mark Init/Dealloc Methods

- (id)initWithModel:(id)model number:(NSUInteger)number port:(NSUInteger)port;
{
    if (self = [super init])
    {
        self.model = model;
        self.number = number;
        
        self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        NSError *error = nil;

        do {
            [self.serverSocket acceptOnPort:port++ error:&error];
        } while (error != nil && error.code == 48);

        self.port = port - 1;

        self.telnetCommands = [NSData dataWithBytes:"\xFF\xFB\x01\xFF\xFB\x03" length:6];
    }
    
    return self;
}

- (void)dealloc;
{
    [self close];
}

- (NSString *)modeName;
{
    NSString *result = @"";
    
    if (self.incomingBuffer == nil && self.outgoingBuffer == nil)
    {
        result = @"Disconnected";
    }
    else
    switch (self.mode)
    {
        case VMODE_COMMAND:
            result = @"Command";
            break;
            
        case VMODE_TCP_SERVER:
            result = @"TCP Server";
            break;
            
        case VMODE_PASSTHRU:
            result = @"Passthrough";
            break;
            
        case VMODE_TCP_CLIENT:
            result = @"TCP Client";
            break;
    }
    
    return result;
}

#pragma clang diagnostic pop

@end
