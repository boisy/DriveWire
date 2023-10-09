//
//  VirtualSerialChannel+TCPCommands.m
//  DriveWire
//
//  Created by Boisy Pitre on 4/23/15.
//
//

#import "VirtualSerialChannel+TCPCommands.h"

@implementation VirtualSerialChannel (TCPCommands)

#pragma mark -
#pragma mark TCP Command Handlers

- (NSError *)handleTCPConnect:(NSArray *)array;
{
    NSError *error = nil;
    
    if ([array count] >= 3)
    {
        NSString *host = [array objectAtIndex:1];
        NSString *port = [array objectAtIndex:2];
        
        dispatch_queue_t dQ = dispatch_queue_create("delegate_queue", nil);
        dispatch_queue_t sQ = dispatch_queue_create("socket_queue", nil);
        
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                 delegateQueue:dQ
                                                   socketQueue:sQ];
        [self.clientSocket connectToHost:host onPort:[port integerValue] error:&error];
    }
    
    return error;
}

- (NSError *)handleTCPListen:(NSArray *)array;
{
    NSError *error = nil;
    
    if ([array count] >= 2)
    {
        NSString *port = [array objectAtIndex:1];
        
        dispatch_queue_t dQ = dispatch_queue_create("delegate_queue", nil);
        dispatch_queue_t sQ = dispatch_queue_create("socket_queue", nil);
        
        GCDAsyncSocket *listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                          delegateQueue:dQ
                                                            socketQueue:sQ];
        BOOL ok = [listenSocket acceptOnPort:[port integerValue] error:&error];
        if (ok != YES)
        {
            NSData *data = [@"FAIL\x0A\x0D" dataUsingEncoding:NSASCIIStringEncoding];
            [self.incomingBuffer appendData:data];
        }
        else
        {
            if (self.listenSockets == nil)
            {
                self.listenSockets = [NSMutableArray array];
            }
            
            [self.listenSockets addObject:listenSocket];
            NSData *data = [@"SUCCESS\x0A\x0D" dataUsingEncoding:NSASCIIStringEncoding];
            [self.incomingBuffer appendData:data];

            // process parameters, if any...
            if ([array count] >= 3)
            {
                for (int i = 2; i < [array count]; i++)
                {
                    NSString *parameter = [array objectAtIndex:i];
                    if ([parameter isEqualToString:@"telnet"])
                    {
                        self.telnetMode = YES;
                    }
                }
            }
        }
    }
    
    return error;
}

- (NSError *)handleTCPJoin:(NSArray *)array;
{
    NSError *error = nil;
    
    if ([array count] >= 2)
    {
        NSString *connection = [array objectAtIndex:1];
        NSUInteger connectionNumber = [connection intValue];
        
        if ([[GlobalChannelArray sharedArray] count] > connectionNumber)
        {
            GCDAsyncSocket *socket = [[GlobalChannelArray sharedArray] objectAtIndex:connectionNumber];
            
            if ([socket isKindOfClass:[GCDAsyncSocket class]])
            {
                self.serverSocket = socket;
                self.serverSocket.delegate = self;
                NSData *data = [@"SUCCESS\x0A\x0D" dataUsingEncoding:NSASCIIStringEncoding];
                [self.incomingBuffer appendData:data];
                self.mode = VMODE_PASSTHRU;
                self.telnetMode = FALSE;
                [socket readDataWithTimeout:READ_TIMEOUT tag:READTAG_DATA_READ];
            }
            else
            {
                NSData *data = [@"FAIL\x0A\x0D" dataUsingEncoding:NSASCIIStringEncoding];
                [self.incomingBuffer appendData:data];
            }
        }
    }
    
    return error;
}

- (NSError *)handleTCPKill:(NSArray *)array;
{
    NSError *error = nil;
    
    if ([array count] >= 2)
    {
        NSString *connection = [array objectAtIndex:1];
        NSUInteger connectionNumber = [connection integerValue];
        
        if ([[GlobalChannelArray sharedArray] count] > connectionNumber)
        {
            GCDAsyncSocket *socket = [[GlobalChannelArray sharedArray] objectAtIndex:connectionNumber];
            if ([socket isKindOfClass:[GCDAsyncSocket class]])
            {
                [socket disconnect];
                [[GlobalChannelArray sharedArray] replaceObjectAtIndex:connectionNumber withObject:[NSNull null]];
            }
        }
        else
        {
            
        }
    }
    
    return error;
}

- (NSError *)handleTCPCommand:(NSArray *)array;
{
    NSError *error = nil;
    BOOL showHelp = TRUE;

    if ([array count] > 1)
    {
        NSDictionary *commandDictionary = @{@"connect" : @"handleTCPConnect:",
                                            @"listen"  : @"handleTCPListen:",
                                            @"join"    : @"handleTCPJoin:",
                                            @"kill"    : @"handleTCPKill:"};
        
        NSString *command = [array objectAtIndex:1];
        NSString *selectorString = [commandDictionary objectForKey:command];
        if (nil != selectorString)
        {
            SEL selector = NSSelectorFromString(selectorString);
            error = [self performSelector:selector withObject:[array subarrayWithRange:NSMakeRange(1, [array count] - 1)]];
            showHelp = FALSE;
        }
    }
    
    if (showHelp == TRUE)
    {
        // show help
        NSData *data = [@"tcp commands:\x0A\x0D"
                        "    connect <server> <port> - connect to server @ port\x0A\x0D"
                        "    listen <port>           - list on port\x0A\x0D"
                        "    join                    - join\x0A\x0D"
                        "    kill                    - kill\x0A\x0D"
                        dataUsingEncoding:NSASCIIStringEncoding];
        [self.incomingBuffer appendData:data];
    }
    
    return error;
}

@end
