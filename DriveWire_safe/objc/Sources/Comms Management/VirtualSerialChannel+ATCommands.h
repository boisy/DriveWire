//
//  VirtualSerialChannel+ATCommands.h
//  DriveWire
//
//  Created by Boisy Pitre on 4/23/15.
//
//

#import "VirtualSerialChannel.h"

@interface VirtualSerialChannel (ATCommands)

- (NSError *)handleATCommand:(NSArray *)commandArray;

@end
