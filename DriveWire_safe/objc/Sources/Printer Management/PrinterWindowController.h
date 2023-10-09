//
//  PrinterWindowController.h
//  DriveWire
//
//  Created by Boisy Pitre on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PrinterWindowController : NSWindowController 
{
    IBOutlet NSTextView *printView;
}

- (void)windowDidLoad;
- (void)updatePrintBuffer:(NSData *)data;
- (IBAction)clear:(id)sender;
- (IBAction)printBuffer:(id)sender;

@end
