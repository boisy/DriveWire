//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


/*!
 @header BGPLog.h
 @copyright Boisy G. Pitre
 @abstract A flexible logging class.
 @discussion Logging is a critical component in applications, especially when tracking down issues or
 trying to trace behavior. The BGPLog class was designed to provide a powerful set of logging capabilities
 in an easy to use, simple package.
 @updated 2012-06-28
 */

#define kBGPLogNotification @"BGPLogNotification"


/*!
 @typedef BGPLogLevel
 @discussion The values in the enumeration indicate the log levels.
 */
typedef enum
{
    BGPLogLevelError = 0,
    BGPLogLevelWarning = 1,
    BGPLogLevelInfo = 2,
    BGPLogLevelDebug = 3,
    BGPLogLevelVerbose = 4,
} BGPLogLevel;

#define BGPLogFormat(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

// Convenience macros
// Set the log level
#define  BGPLogLevel(lvl)              [[BGPLog sharedLog] setLogLevel:lvl]

#define BGPLogError(format, ...)       [[BGPLog sharedLog] logLevel:BGPLogLevelError message:[NSString stringWithFormat:(format), ##__VA_ARGS__]]
#define BGPLogWarning(format, ...)     [[BGPLog sharedLog] logLevel:BGPLogLevelWarning message:[NSString stringWithFormat:(format), ##__VA_ARGS__]]
#define BGPLogInfo(format, ...)        [[BGPLog sharedLog] logLevel:BGPLogLevelInfo message:[NSString stringWithFormat:(format), ##__VA_ARGS__]]
#define BGPLogDebug(format, ...)       [[BGPLog sharedLog] logLevel:BGPLogLevelDebug message:[NSString stringWithFormat:(format), ##__VA_ARGS__]]
#define BGPLogVerbose(format, ...)       [[BGPLog sharedLog] logLevel:BGPLogLevelVerbose message:[NSString stringWithFormat:(format), ##__VA_ARGS__]]

#define kLogState               @"logState"
#define kLogLevel               @"logLevel"
#define kLogStandardError       @"logStandardError"
#define kDebugProfile           @"DebugProfile"
#define kNumberOfDaysToKeepLogs @"logDaysToKeep"

/*!
 @class BGPLog
 @discussion This is a full-featured logging class.
 */
@interface BGPLog : NSObject
{
    NSString        *bundleName;
    NSString        *bundleID;
    NSDictionary    *logTags;
    NSString        *logDirectory;
}

@property (assign) BGPLogLevel logLevel;
@property (assign) BOOL logState;
/*!
 @method sharedLog
 @discussion The singleton object is returned from this class method.
 */

+ (BGPLog *)sharedLog;

- (NSArray *)logLevelNameArray;

/*!
 @method dumpFrames
 @discussion This method dumps the current stack frame.
 */
- (void)dumpFrames;

/*!
 @method logLevel:message:
 @discussion Sends a message to the logging system.
 @param level The log level to send the message as
 @param message The message to send
 */
- (void)logLevel:(BGPLogLevel)level message:(NSString *)message;

/// \brief Send a message to the logging system (backward compatible method)
/// \param level The log level to send the message as
/// \param message The message to send
- (void)log:(NSString *)message level:(BGPLogLevel)level;

/*!
 @method logLevel:message:info:
 @discussion Sends a message to the logging system.
 @param level The log level to send the message as
 @param message The message to send
 @param msgInfo Name value pairs to be associated with the logged message
 */
- (void)logLevel:(BGPLogLevel)level message:(NSString *)message info:(NSDictionary *)msgInfo;

/*!
 @method logLevel:message:uti:attachmentName:attachment:
 @discussion Sends a message to the logging system along with an attachment.
 @param level The log level to send the message as
 @param message The message to send
 @param uti The uniform type identifier to send
 @param attachmentName The name of the file that the attachment will be saved to
 @param attachment The attachment data
 */
- (void)logLevel:(BGPLogLevel)level message:(NSString *)message uti:(NSString *)uti attachmentName:(NSString *)attachmentName attachment:(NSData *)attachment;

/*!
 @method logLevel:message:uti:url:
 @discussion Sends a message to the logging system along with a URL.
 @param level The log level to send the message as
 @param message The message to send
 @param uti The uniform type identifier to send
 @param url The URL to send
 */
- (void)logLevel:(BGPLogLevel)level message:(NSString *)message uti:(NSString *)uti url:(NSString *)url;

/*!
 @method setLogLevelFromString:
 @discussion Set the log level using a string.
 @param level The log level string to set the logging system to
 */
- (void)setLogLevelFromString:(NSString *)level;

/*!
 @method setLogLevelFromString:
 @discussion Set the log level.
 @param level The log level to set the logging system to
 */
- (void)setLogLevel:(BGPLogLevel)level;

/*!
 @method start
 @discussion When called, this method starts the logger.
 */
- (void)start;

/*!
 @method stop
 @discussion When called, this method stops the logger.
 */
- (void)stop;

/*!
 @method showInConsole
 @discussion Launches the Console with the current log in view
 */
- (void)showInConsole;

@end


// BGPLog Macros

#define BGPError(format, ...)       {\
    NSString *_ddMsg = [NSString stringWithFormat:(format @" #%@"), ##__VA_ARGS__, [self className]];\
    [[BGPLog sharedLog] logLevel:BGPLogLevelError message:_ddMsg];\
}

#define BGPWarning(format, ...)       {\
    NSString *_ddMsg = [NSString stringWithFormat:(format @" #%@"), ##__VA_ARGS__, [self className]];\
    [[BGPLog sharedLog] logLevel:BGPLogLevelWarning message:_ddMsg];\
}

#define BGPInfo(format, ...)       {\
    NSString *_ddMsg = [NSString stringWithFormat:(format @" #%@"), ##__VA_ARGS__, [self className]];\
    [[BGPLog sharedLog] logLevel:BGPLogLevelInfo message:_ddMsg];\
}

#define BGPDebug(format, ...)       {\
    NSString *_ddMsg = [NSString stringWithFormat:(format @" #%@"), ##__VA_ARGS__, [self className]];\
    [[BGPLog sharedLog] logLevel:BGPLogLevelDebug message:_ddMsg];\
}

#define BGPVerbose(format, ...)       {\
    NSString *_ddMsg = [NSString stringWithFormat:(format @" #%@"), ##__VA_ARGS__, [self className]];\
    [[BGPLog sharedLog] logLevel:BGPLogLevelVerbose message:_ddMsg];\
}

#ifndef NDEBUG
#define BGPLog(format, ...)         {\
    NSString *_sourceFile = [[NSString stringWithUTF8String:__FILE__] lastPathComponent];\
    NSDictionary *_ddInfo = [NSDictionary dictionaryWithObjectsAndKeys:\
        [NSString stringWithFormat:@"%@:%d",_sourceFile,__LINE__], @"SourceFile",\
        [NSString stringWithUTF8String:__PRETTY_FUNCTION__], @"SourceMethod",\
        nil];\
    NSString *_ddMsg = [NSString stringWithFormat:(format @" #%@"), ##__VA_ARGS__, [self className]];\
    [[BGPLog sharedLog] logLevel:BGPLogLevelDebug message:_ddMsg info:_ddInfo];\
}
#else
#define BGPLog(format, ...) 
#endif

#define DDFatalException(ex, format, ...)       {\
    NSString *_ddMsg = [NSString stringWithFormat:(format @"%@ %@ #%@"), ##__VA_ARGS__, GTMStackTraceFromException(ex), [self className]];\
    [[BGPLog sharedLog] logLevel:BGPLogLevelCritical message:_ddMsg];\
}
