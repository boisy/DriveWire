//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


#define	BGPErrorDomain @"org.pitre.DriveWire.ErrorDomain"

// Error codes
#define BGPErrorDomain                    @"org.pitre.DriveWire.ErrorDomain"

#define BGPErrorBadNetworkAddress        -101
#define BGPErrorSocketAlreadyOpen        -102
#define BGPErrorUnsupportedDataFormat    -104
#define BGPErrorStopCancelled            -105
#define BGPErrorPlugInLoadFailure        -106
#define BGPErrorMissingPlugIn            -107
#define BGPErrorSiteDocumentLoadFailure  -108
#define BGPErrorSiteDocumentImportFailure  -109
#define BGPErrorScriptExecutionFailure   -110
#define BGPErrorNoAgentPlugIns           -111
#define BGPErrorPlugInAlreadyStarted     -112
#define BGPErrorPlugInAlreadyStopped     -113
#define BGPErrorPlugInAlreadyEnabled     -114
#define BGPErrorPlugInAlreadyDisabled    -115
#define BGPErrorDeviceConfiguration      -116
#define BGPErrorSerialPortAlreadyOpen	    -117
#define BGPErrorSerialPortFailedToOpen    -118
#define BGPErrorSerialPortNonExistent	    -119
#define BGPErrorSerialPortAlreadyReserved -120
#define BGPErrorInvalidAddress		    -121
#define BGPErrorMalformedURL	             -122
#define BGPErrorFailedToConnect			-123
#define BGPErrorFileDoesntExist            -124
#define BGPErrorUnsupportedPollInterval     -125

@interface NSError (BGP)

+ (NSError *)badNetworkAddress;
+ (NSError *)socketAlreadyOpen;
+ (NSError *)unsupportedDataFormat;
+ (NSError *)stopCancelled;
+ (NSError *)plugInLoadFailure;
+ (NSError *)missingPlugIn;
+ (NSError *)siteDocumentLoadFailure;
+ (NSError *)siteDocumentLoadFailure:(NSString *)message;
+ (NSError *)siteDocumentImportFailure;
+ (NSError *)siteDocumentImportFailure:(NSString *)message;
+ (NSError *)scriptExecutionFailure:(NSString *)message;
+ (NSError *)noAgentPlugIns;
+ (NSError *)plugInAlreadyStarted;
+ (NSError *)plugInAlreadyStopped;
+ (NSError *)plugInAlreadyEnabled;
+ (NSError *)plugInAlreadyDisabled;
+ (NSError *)deviceConfiguration;
+ (NSError *)serialPortFailedToOpen:(NSString *)message;
+ (NSError *)serialPortAlreadyOpen;
+ (NSError *)serialPortNonExistent;
+ (NSError *)serialPortAlreadyReserved;
+ (NSError *)invalidAddress;
+ (NSError *)malformedURL;
+ (NSError *)failedToConnect;
+ (NSError *)fileDoesntExist;
+ (NSError *)unsupportedPollInterval;

@end
