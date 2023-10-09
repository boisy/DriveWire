//
//  VirtualDriveJukeBoxView.m
//  DriveWire
//
//  Created by Boisy Pitre on 12/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "VirtualDriveJukeBoxView.h"


@implementation VirtualDriveJukeBoxView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
        // Initialization code here.
    }

    return self;
}

- (void)addSubview:(NSView *)view
{
    NSUInteger driveCount;
    NSRect   viewFrame;
    float    verticalPadding = 0.0f;
    NSRect   myFrame;
    float    boundsHeight;
	
    driveCount = [[self subviews] count];
    viewFrame = [view frame];
    viewFrame.origin.y = (viewFrame.size.height + verticalPadding) * driveCount;
    [view setFrame: viewFrame];
	
	boundsHeight = (viewFrame.size.height + verticalPadding) * (driveCount + 1);
    myFrame = [self frame];
	myFrame.size.width = viewFrame.size.width;
    myFrame.size.height = boundsHeight;
	
	// Resize our JukeBox view
	//    [self setBounds:NSMakeRect(0, 0, myFrame.size.width, myFrame.size.height)];
	[self setFrame:myFrame];
	
	[super addSubview:view];	
}

#if 0
- (void) addVirtualDriveView:(VirtualDriveView *)view
{
    unsigned driveCount;
    NSRect   viewFrame;
    float    verticalPadding = 0.0f;
    NSRect   myFrame;
    float    boundsHeight;

	[self addSubview:view];

    driveCount = [[self subviews] count] - 1;
    viewFrame = [view frame];
    viewFrame.origin.y = (viewFrame.size.height + verticalPadding) * driveCount;
    [view setFrame: viewFrame];
	
	boundsHeight = (viewFrame.size.height + verticalPadding) * (driveCount + 1);
    myFrame = [self frame];
	myFrame.size.width = viewFrame.size.width;
    myFrame.size.height = boundsHeight;

	// Resize our JukeBox view
//    [self setBounds:NSMakeRect(0, 0, myFrame.size.width, myFrame.size.height)];
	[self setFrame:myFrame];

	[self setNeedsDisplay:YES];
}

- (void) didAddSubview:(NSView *) view
{
    unsigned int driveCount = [[self subviews] count];
	
    NSRect viewFrame = [view frame];
#if 0
    viewFrame.origin.y = (viewFrame.size.height  * (driveCount - 1));
    [view setFrameOrigin: viewFrame.origin];
#endif
	
    NSRect myFrame = [self frame];
#if 0
    myFrame.size.width = viewFrame.size.width;
    myFrame.size.height = (viewFrame.size.height * driveCount);
    [self setFrame: myFrame];
#endif

    BGPDebug(@"view: %@, frame: %@, my frame: %@", view, NSStringFromRect([view frame]), NSStringFromRect([self frame]));
}
#endif

@end
