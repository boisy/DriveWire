//
//  DebuggerWindowController.h
//  DriveWire
//
//  Created by Boisy Pitre on 3/13/09.
//  Copyright 2009 Tee-Boy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MemoryView.h"
#import "RegisterView.h"
#import "DisassemblerView.h"

@interface DebuggerWindowController : NSWindowController
{
   IBOutlet MemoryView *memoryView;
   IBOutlet RegisterView *registerView;
   IBOutlet DisassemblerView *disassemblerView;
}

- (void)updateRegisters:(NSDictionary *)info;
- (void)updateMemory:(NSDictionary *)info;
- (void)updateDisassembler:(NSDictionary *)info;

@end
