//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------

@interface BGPLEDView : NSView

@property (assign) BOOL state;
@property (assign) CGFloat value;
@property (strong) NSColor *onColor;
@property (strong) NSColor *offColor;
@property (assign) BOOL drawHighlight;
@property (assign) CGFloat blinkTime;

- (void)blink;
- (void)turnOn;
- (void)turnOff;

@end
