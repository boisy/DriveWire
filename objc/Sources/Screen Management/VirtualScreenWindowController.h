//
//  VirtualScreenWindowController.h
//  DriveWire
//
//  Created by Boisy Pitre on 12/27/17.
//

#import <Cocoa/Cocoa.h>
#import "VirtualScreenView.h"

FOUNDATION_EXPORT NSString *const kVirtualScreenOpenedNotification;
FOUNDATION_EXPORT NSString *const kVirtualScreenClosedNotification;

@interface VirtualScreenWindowController : NSWindowController

@property (assign) NSUInteger number;

- (id)initWithModel:(id)model number:(NSUInteger)number port:(NSUInteger)port;

- (void)putByte:(u_char)byte;
- (void)reset;

@end
