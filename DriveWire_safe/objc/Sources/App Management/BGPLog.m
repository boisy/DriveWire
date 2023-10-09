
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
#import <execinfo.h>
#import "NSString+Additions.h"

#define LOG_LEVEL_DEF ddLogLevel
#import "CocoaLumberjack.h"
//@import CocoaLumberjack;
static DDLogLevel ddLogLevel = DDLogLevelInfo;

@implementation BGPLog

@synthesize logLevel = _logLevel;

#pragma mark -
#pragma mark Singleton Methods

+ (void)initialize;
{
    // register some sensible default values here...
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:TRUE], kLogState,
                              [NSNumber numberWithBool:TRUE], kLogStandardError,
                              [NSNumber numberWithInt:0], kDebugProfile,
                              [NSNumber numberWithInt:BGPLogLevelDebug], kLogLevel,
                              [NSNumber numberWithInt:30], kNumberOfDaysToKeepLogs,
                              nil];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	// expose our log level as a binding
	[BGPLog exposeBinding:@"logLevel"];
	[BGPLog exposeBinding:@"logState"];	
}

#pragma mark -
#pragma mark Singleton Methods

static BGPLog *sharedLog = nil;
static NSArray *names = nil;

+ (BGPLog *)sharedLog;
{
	@synchronized(self)
	{
		if (sharedLog == nil)
		{
			sharedLog = [BGPLog new];
            BGPLogLevel level = [[[NSUserDefaults standardUserDefaults] objectForKey:kLogLevel] intValue];
            [sharedLog setLogLevel:level];
			[sharedLog start];

            [DDLog addLogger:[DDOSLogger sharedInstance]]; // Uses os_log
            
            DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
            fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
            fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
            [DDLog addLogger:fileLogger];
        }
	}
    
    return sharedLog;
}

+ (id)xallocWithZone:(NSZone *)zone;
{
    @synchronized(self)
	{
        if (sharedLog == nil)
		{
            sharedLog = [super allocWithZone:zone];
            return sharedLog;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone;
{
    return self;
}


#pragma mark -
#pragma mark Private Methods

- (BOOL)string:(NSString *)target endsWithString:(NSString *)s;
{
	BOOL result = FALSE;
	
	NSRange r = [target rangeOfString:s];
	
	if (r.location != NSNotFound)
	{
		if (r.location + r.length == [target length])
		{
			result = TRUE;
		}
	}
	
	return result;
}

#pragma mark -
#pragma mark Init/Dealloc Methods

- (id)init;
{
    if (self = [super init])
    {
        // add ourself as an observer of these preferences
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kLogState options:NSKeyValueObservingOptionNew context:nil];
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kLogLevel options:NSKeyValueObservingOptionNew context:nil];
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kLogStandardError options:NSKeyValueObservingOptionNew context:nil];
        
        // set up bundle name and identifier
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSDictionary *bundleInfo = [mainBundle infoDictionary];
        bundleName = (NSString *)[bundleInfo valueForKey:(NSString *)kCFBundleNameKey];
        bundleID = [mainBundle bundleIdentifier];
    }
    
    return self;
}

- (void)dealloc;
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kLogLevel];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kLogState];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kLogStandardError];
}

#pragma mark -
#pragma mark Logging Methods

- (NSString *)frameString;
{
	void *backtraceFrames[128];
	int frameCount = backtrace(&backtraceFrames[0], 128);
	char **frameStrings = backtrace_symbols(&backtraceFrames[0], frameCount);
	NSInteger x;
	NSMutableString *bigDump = [NSMutableString new];
    [bigDump appendString:@">> #StackTrace\n"];
	
	// dump whatever symbols we can (the ones in the system libraries will show up well, the ones in our code will not, see below)
	
	if(frameStrings != NULL) {
		for(x = 1; x < frameCount; x++) { // start at 1 because we already know we're in dump_frames
			if(frameStrings[x] == NULL) { break; }
            [bigDump appendFormat:@"%s\n", frameStrings[x]];
		}
		free(frameStrings);
	}
	
    [bigDump appendString:@"*****"];
	
	// then dump an atos-formatted string for entry into Terminal (the ones in our code will be able to be atos'ed, and the ones
	// in the library will not be, making it the opposite of the trace above so we can fill in the gaps)
	
	NSMutableString * atosString = [NSMutableString stringWithFormat:@"atos -o \"%@\"", [[[NSBundle mainBundle] executablePath] lastPathComponent]];
	for(x = 1; x < frameCount; x++) { // start at 1 because we already know we're in dump_frames
		[atosString appendFormat:@" %p", backtraceFrames[x]];
	}
	[atosString appendString:@"\n<< StackTrace\n"];
    [bigDump appendString:@"\n"];
	
    return bigDump;
}

- (void)dumpFrames;
{
    NSString *frames = [self frameString];

    [self logLevel:BGPLogLevelError message:@"Stack frame dump" uti:nil attachmentName:@"stack_dump" attachment:[frames dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context;
{
    if ([keyPath isEqualToString:kLogState])
    {
        BOOL state = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (state)
        {
            [self start];
        }
        else
        {
            [self stop];
        }
	}
	else if ([keyPath isEqualToString:kLogLevel])
    {
        id obj = [change objectForKey:NSKeyValueChangeNewKey];
        
        if ([obj isKindOfClass:[NSNumber class]])
        {
            [self setLogLevel:[obj intValue]];
        }
        else
        {
            [self setLogLevelFromString:obj];
        }
    }
}

- (NSArray *)logLevelNameArray;
{
    if (names == nil)
    {
        names = [NSArray arrayWithObjects:
                 @"Error",
                 @"Warning",
                 @"Info",
                 @"Debug",
                 @"Verbose",
                 nil];
    }
    
    return names;
}

// This is a private method that handles all possible logging options... we simply call into it from other methods for simplicity
- (void)logLevel:(BGPLogLevel)level
   keysAndValues:(NSDictionary *)keysAndValues
      identifier:(NSString *)identifier
        facility:(NSString *)facility
         message:(NSString *)message
             uti:(NSString *)uti
             url:(NSString *)url
  attachmentName:(NSString *)attachmentName
      attachment:(NSData *)attachment;
{
    // if logging is not turned on or the level is beyond the threshold, return immediately
    if (self.logState == NO || self.logLevel < level)
    {
        return;
    }
    
    NSString *messageToLog = [message stringByEscapingNonPrintableCharacters];
    
    // here we log the message
    switch (self.logLevel)
    {
        case BGPLogLevelWarning:
            DDLogWarn(@"%@", messageToLog);
            break;

        case BGPLogLevelInfo:
            DDLogInfo(@"%@", messageToLog);
            break;
            
        case BGPLogLevelVerbose:
            DDLogVerbose(@"%@", messageToLog);
            break;

        case BGPLogLevelDebug:
            DDLogDebug(@"%@", messageToLog);
            break;

        case BGPLogLevelError:
            DDLogError(@"%@", messageToLog);
            break;
    }
    
    // post the log information as a notification for any interested parties
    NSDictionary *logDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:level], @"level",
                             identifier ? identifier : @"", @"identifier",
                             facility ? facility : @"", @"facility",
                             message ? message : @"", @"message",
                             uti ? uti : @"", @"uti",
                             url ? url : @"", @"url",
                             attachmentName ? attachmentName : @"", @"attachmentName",
                             attachment ? attachment : (NSData *)[NSNull null], @"attachment",
                             nil
                             ];
    
    NSNotification *log = [NSNotification notificationWithName:kBGPLogNotification object:logDict];
    [[NSNotificationCenter defaultCenter] postNotification:log];
}

- (void)logLevel:(BGPLogLevel)level message:(NSString *)message uti:(NSString *)uti attachmentName:(NSString *)attachmentName attachment:(NSData *)attachment;
{
    [self logLevel:level keysAndValues:nil identifier:bundleID facility:bundleName message:message uti:uti url:nil attachmentName:attachmentName attachment:attachment];
}

// this method exists for backward compatibility
- (void)log:(NSString *)message level:(BGPLogLevel)level;
{
    [self logLevel:level message:message];
}

- (void)logLevel:(BGPLogLevel)level message:(NSString *)message;
{
    [self logLevel:level keysAndValues:nil identifier:bundleID facility:bundleName message:message uti:nil url:nil attachmentName:nil attachment:nil];
}

- (void)logLevel:(BGPLogLevel)level message:(NSString *)message info:(NSDictionary *)msgInfo;
{
    [self logLevel:level keysAndValues:msgInfo identifier:bundleID facility:bundleName message:message uti:nil url:nil attachmentName:nil attachment:nil];
}

- (void)logLevel:(BGPLogLevel)level message:(NSString *)message uti:(NSString *)uti url:(NSString *)url;
{
    [self logLevel:level keysAndValues:nil identifier:bundleID facility:bundleName message:message uti:uti url:url attachmentName:nil attachment:nil];
}

- (void)setLogLevelFromString:(NSString *)level;
{
    if (level == nil)
    {
        return;
    }
    
    if ([level caseInsensitiveCompare:@"error"] == NSOrderedSame)
    {
        [self setLogLevel:BGPLogLevelError];
    }
    else
    if ([level caseInsensitiveCompare:@"warning"] == NSOrderedSame)
    {
        [self setLogLevel:BGPLogLevelWarning];
    }
    else
    if ([level caseInsensitiveCompare:@"info"] == NSOrderedSame)
    {
        [self setLogLevel:BGPLogLevelInfo];
    }
    else
    if ([level caseInsensitiveCompare:@"debug"] == NSOrderedSame)
    {
        [self setLogLevel:BGPLogLevelDebug];
    }
    else
    if ([level caseInsensitiveCompare:@"verbose"] == NSOrderedSame)
    {
        [self setLogLevel:BGPLogLevelVerbose];
    }
}

- (BGPLogLevel)logLevel;
{
    return _logLevel;
}

- (void)setLogLevel:(BGPLogLevel)level;
{
    switch (level)
    {
        case BGPLogLevelError:
            ddLogLevel = DDLogLevelError;
            break;
            
        case BGPLogLevelWarning:
            ddLogLevel = DDLogLevelWarning;
            break;

        case BGPLogLevelInfo:
            ddLogLevel = DDLogLevelInfo;
            break;

        case BGPLogLevelDebug:
            ddLogLevel = DDLogLevelDebug;
            break;
            
        case BGPLogLevelVerbose:
            ddLogLevel = DDLogLevelVerbose;
            break;
    }
    
    _logLevel = level;
}

- (void)start;
{
    self.logState = YES;
}

- (void)stop;
{
    self.logState = NO;
}

- (void)showInConsole;
{
    NSString *logFilePath = nil;
    
    // hunt a file logger
    NSArray *loggers = [[DDLog sharedInstance] allLoggers];
    for (DDLog *log in loggers)
    {
        if ([log isKindOfClass:[DDFileLogger class]])
        {
            DDFileLogger *fileLogger = (DDFileLogger *)log;
            DDLogFileInfo *i = fileLogger.currentLogFileInfo;
            logFilePath = i.filePath;
        }
    }
    
    if (logFilePath != nil)
    {
        NSURL *url = [NSURL fileURLWithPath:logFilePath];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

@end
