//
//  PrinterWindowController.m
//  DriveWire
//
//  Created by Boisy Pitre on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PrinterWindowController.h"


@implementation PrinterWindowController


- (void)awakeFromNib;
{
   [printView setFont:[NSFont fontWithName:@"Courier New" size:12]];
   [printView setEditable:FALSE];
}

- (void)windowDidLoad;
{
   [[self window] orderOut:nil]; // to hide it
}

- (void)updatePrintBufferMainThread:(NSData *)data;
{
    NSString *s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    [printView setEditable:TRUE];
    NSRange range = {[[printView string] length], 0};
    [printView setSelectedRange:range];
    [printView insertText:s];
    [printView setEditable:FALSE];
    [self showWindow:self];
}

- (void)updatePrintBuffer:(NSData *)data;
{
    [self performSelectorOnMainThread:@selector(updatePrintBufferMainThread:) withObject:data waitUntilDone:YES];
}

- (IBAction)clear:(id)sender;
{
    [printView setEditable:TRUE];
    [printView selectAll:sender];
    [printView cut:sender];
    [printView setEditable:FALSE];
}

- (IBAction)printBuffer:(id)sender;
{
    // set printing properties
    NSPrintInfo *myPrintInfo = [NSPrintInfo sharedPrintInfo];
    [myPrintInfo setHorizontalPagination:NSFitPagination];
    [myPrintInfo setHorizontallyCentered:NO];
    [myPrintInfo setVerticallyCentered:NO];
    [myPrintInfo setLeftMargin:72.0];
    [myPrintInfo setRightMargin:72.0];
    [myPrintInfo setTopMargin:72.0];
    [myPrintInfo setBottomMargin:90.0];

    NSTextView *pv = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 8.5 * 72, 11.0 * 72)];
    NSPrintOperation *op;

    NSRange textViewRange = NSMakeRange(0, [[printView textStorage] length]);
    NSRange printViewRange = NSMakeRange(0, [[pv textStorage] length]);

    [pv replaceCharactersInRange:printViewRange withRTF:[printView RTFFromRange:textViewRange]];
    op = [NSPrintOperation printOperationWithView:pv printInfo:myPrintInfo];
    [op setShowsPrintPanel:YES];
    [op runOperationModalForWindow:[self window] delegate:nil didRunSelector:NULL contextInfo:NULL];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName;
{
    return [NSString stringWithFormat:@"Virtual Printer - %@", displayName];
}

@end
