//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


#import "NSError+BGP.h"


@implementation NSError (BGP)

+ (NSError *)serialPortFailedToOpen:(NSString *)message;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorSerialPortFailedToOpen userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																									 @"Failed To Open Port", NSLocalizedDescriptionKey,
																									 @"The requested port could not be acquired due to an error.", NSLocalizedFailureReasonErrorKey,
																									 message, NSLocalizedRecoverySuggestionErrorKey,
																									 nil]];
}

+ (NSError *)serialPortAlreadyOpen;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorSerialPortAlreadyOpen userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																									@"Serial Port Already In Use", NSLocalizedDescriptionKey,
																									@"The requested serial port is being used elsewhere on the system.", NSLocalizedFailureReasonErrorKey,
																									@"Ensure no other application is using the serial port.", NSLocalizedRecoverySuggestionErrorKey,
																									nil]];
}

+ (NSError *)serialPortNonExistent;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorSerialPortNonExistent userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																										@"Serial Port Does Not Exist", NSLocalizedDescriptionKey,
																										@"The requested serial port does not exist on the system.", NSLocalizedFailureReasonErrorKey,
																										@"Verify that you have selected a valid serial port.", NSLocalizedRecoverySuggestionErrorKey,
																										nil]];
}

+ (NSError *)serialPortAlreadyReserved;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorSerialPortAlreadyReserved userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																									  @"Serial Port Already Reserved", NSLocalizedDescriptionKey,
																									  @"The requested serial port is being used elsewhere on the system.", NSLocalizedFailureReasonErrorKey,
																									  @"Ensure no other application is using the serial port.", NSLocalizedRecoverySuggestionErrorKey,
																								  nil]];
}

+ (NSError *)malformedURL;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorMalformedURL userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																						 @"Malformed URL", NSLocalizedDescriptionKey,
																						 @"The URL is malformed.", NSLocalizedFailureReasonErrorKey,
																						 @"Check the URL for correctness.", NSLocalizedRecoverySuggestionErrorKey,
																						 nil]];
}

+ (NSError *)invalidAddress;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorInvalidAddress userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"Invalid Address", NSLocalizedDescriptionKey,
                                                                                            @"Either the address is empty, or it is not properly formed.", NSLocalizedFailureReasonErrorKey,
                                                                                            @"Check the network address for correctness.",NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)failedToConnect;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorFailedToConnect userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																						 @"Failed To Connect", NSLocalizedDescriptionKey,
																						 @"The connection to the server failed.", NSLocalizedFailureReasonErrorKey,
																						 @"Check the connection string for correctness.", NSLocalizedRecoverySuggestionErrorKey,
																						 nil]];
}

+ (NSError *)fileDoesntExist;
{
	return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorFileDoesntExist userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"File Doesn't Exist", NSLocalizedDescriptionKey,
                                                                                            @"The specified file does not exist.", NSLocalizedFailureReasonErrorKey,
                                                                                            @"Please ensure that the file exists.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)badNetworkAddress;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorBadNetworkAddress userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"Bad Network Address", NSLocalizedDescriptionKey,
                                                                                            @"The network address is incorrect.", NSLocalizedFailureReasonErrorKey,
                                                                                            @"Verify that the network address is a legal DNS name or IP address.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)socketAlreadyOpen;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorSocketAlreadyOpen userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"Socket Already Open", NSLocalizedDescriptionKey,
                                                                                            @"The socket is already open.", NSLocalizedFailureReasonErrorKey,
                                                                                            @"Ensure that the address is not already in use.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)unsupportedDataFormat;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorUnsupportedDataFormat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                @"Unsupported Data Format", NSLocalizedDescriptionKey,
                                                                                                @"The file does not appear to contain a supported data format.", NSLocalizedFailureReasonErrorKey,
                                                                                                @"Please choose a file that contains a supported data format.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                                nil]];
}

+ (NSError *)stopCancelled;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorStopCancelled userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                        @"Stop Agent Cancelled", NSLocalizedDescriptionKey,
                                                                                        @"The user cancelled the Stop Agent operation.", NSLocalizedFailureReasonErrorKey,
                                                                                        @"This was a user-initiated operation.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                        nil]];
}

+ (NSError *)missingPlugIn;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorPlugInLoadFailure userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"Missing Plug-In", NSLocalizedDescriptionKey,
                                                                                            @"An expected plug-in is missing.", NSLocalizedFailureReasonErrorKey,
                                                                                            @"Verify that the plug-in has not been moved or deleted.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)plugInLoadFailure;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorPlugInLoadFailure userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"Plug-In Load Failure", NSLocalizedDescriptionKey,
                                                                                            @"The plug-in failed to load.", NSLocalizedFailureReasonErrorKey,
                                                                                            @"Verify that the plug-in meets the plug-in API version requirements.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)siteDocumentLoadFailure;
{
    return [NSError siteDocumentLoadFailure:@"There is likely damage to the file."];
}

+ (NSError *)siteDocumentLoadFailure:(NSString *)message;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorSiteDocumentLoadFailure userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"Error Loading Site Document", NSLocalizedDescriptionKey,
                                                                                            @"", NSLocalizedFailureReasonErrorKey,
                                                                                            message, NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)siteDocumentImportFailure;
{
    return [NSError siteDocumentImportFailure:@"There is an incompatible object in the file."];
}

+ (NSError *)siteDocumentImportFailure:(NSString *)message;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorSiteDocumentImportFailure userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            @"An error occurred importing the Site Document.", NSLocalizedDescriptionKey,
                                                                                            @"", NSLocalizedFailureReasonErrorKey,
                                                                                            message, NSLocalizedRecoverySuggestionErrorKey,
                                                                                            nil]];
}

+ (NSError *)scriptExecutionFailure:(NSString *)message;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorScriptExecutionFailure userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                 @"Error Executing Script", NSLocalizedDescriptionKey,
                                                                                                 message, NSLocalizedFailureReasonErrorKey,
                                                                                                 @"Check the contents of the script for correctness and proper syntax.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                                 nil]];
}

+ (NSError *)noAgentPlugIns;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorScriptExecutionFailure userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                 @"No Agent Plug-Ins", NSLocalizedDescriptionKey,
                                                                                                 @"No agent plug-ins were found.", NSLocalizedFailureReasonErrorKey,
                                                                                                 @"At least one agent plug-in is required in order to function.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                                 nil]];
}

+ (NSError *)plugInAlreadyStarted;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorPlugInAlreadyStarted userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                               @"Plug-In already started", NSLocalizedDescriptionKey,
                                                                                               @"The plug-in was running when it was asked to start.", NSLocalizedFailureReasonErrorKey,
                                                                                               @"Don't call this method if the plug-jn is already running.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                               nil]];
}

+ (NSError *)plugInAlreadyStopped;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorPlugInAlreadyStopped userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                               @"Plug-In already stopped", NSLocalizedDescriptionKey,
                                                                                               @"The plug-in was stopped when it was asked to stop.", NSLocalizedFailureReasonErrorKey,
                                                                                               @"Don't call this method if the plug-in is already stopped.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                               nil]];
}

+ (NSError *)plugInAlreadyEnabled;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorPlugInAlreadyEnabled userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                               @"Plug-In already enabled", NSLocalizedDescriptionKey,
                                                                                               @"The plug-in was enabled when it was asked to enable.", NSLocalizedFailureReasonErrorKey,
                                                                                               @"Don't call this method if the plug-in is already enabled.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                               nil]];
}

+ (NSError *)plugInAlreadyDisabled;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorPlugInAlreadyDisabled userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                @"Plug-In already disabled", NSLocalizedDescriptionKey,
                                                                                                @"The plug-in was disabled when it was asked to disable.", NSLocalizedFailureReasonErrorKey,
                                                                                                @"Don't call this method if the plug-in is already disabled.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                                nil]];
}

+ (NSError *)deviceConfiguration;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorDeviceConfiguration userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                              @"Device Configuration Error", NSLocalizedDescriptionKey,
                                                                                              @"The agent cannot connect because the device is not configured properly.", NSLocalizedFailureReasonErrorKey,
                                                                                              @"Check the connection settings in the agent.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                              nil]];
}

+ (NSError *)unsupportedPollInterval;
{
    return [NSError errorWithDomain:BGPErrorDomain code:BGPErrorUnsupportedPollInterval userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                              @"Unsupported Poll Interval", NSLocalizedDescriptionKey,
                                                                                              @"An unsupported poll interval was specified.", NSLocalizedFailureReasonErrorKey,
                                                                                              @"Ensure the poll interval is within the legal set of intervals.", NSLocalizedRecoverySuggestionErrorKey,
                                                                                              nil]];
}

@end
