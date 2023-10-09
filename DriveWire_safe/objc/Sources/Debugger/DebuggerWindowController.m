//
//  DebuggerWindowController.m
//  DriveWire
//
//  Created by Boisy Pitre on 3/13/09.
//  Copyright 2009 Tee-Boy. All rights reserved.
//

#import "DebuggerWindowController.h"


@implementation DebuggerWindowController

- (void)updateRegisters:(NSDictionary *)info;
{
   [registerView update:info];
}

- (void)updateMemory:(NSDictionary *)info;
{
}

- (void)updateDisassembler:(NSDictionary *)info;
{
}

@end
