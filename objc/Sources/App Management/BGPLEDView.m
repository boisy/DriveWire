//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------

#import "BGPLEDView.h"

@implementation BGPLEDView

@synthesize state = _state;
@synthesize value = _value;
@synthesize onColor = _onColor;
@synthesize offColor = _offColor;

- (instancetype)copyWithZone:(NSZone *)zone;
{
    BGPLEDView *view = [[[self class] alloc] initWithFrame:self.frame];
    view.state = self.state;
    view.onColor = self.onColor;
    view.offColor = self.offColor;
    view.drawHighlight = self.drawHighlight;
    view.blinkTime = self.blinkTime;
    
    return view;
}

- (id)initWithFrame:(NSRect)frame;
{
    if (self = [super initWithFrame:frame])
    {
        self.onColor = [NSColor greenColor];
        self.offColor = [NSColor blackColor];
        self.drawHighlight = TRUE;
        self.blinkTime = 0.1f;
        self.state = NO;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if (self = [super initWithCoder:coder])
    {
        self.onColor = [coder decodeObjectForKey:@"onColor"];
        self.offColor = [coder decodeObjectForKey:@"offColor"];
        self.drawHighlight = [coder decodeBoolForKey:@"drawHighlight"];
        self.blinkTime = [coder decodeFloatForKey:@"blinkTime"];
        self.state = [coder decodeBoolForKey:@"state"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.onColor forKey:@"onColor"];
    [aCoder encodeObject:self.offColor forKey:@"offColor"];
    [aCoder encodeBool:self.drawHighlight forKey:@"drawHighlight"];
    [aCoder encodeFloat:self.blinkTime forKey:@"blinkTime"];
    [aCoder encodeBool:self.state forKey:@"state"];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [NSGraphicsContext saveGraphicsState];
    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];

    NSColor *colorConverted = nil;
    if (self.state == 1)
    {
        colorConverted = [self.onColor colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    }
    else
    {
        colorConverted = [self.offColor colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    }

    CGContextSetLineWidth(ctx, 1);
    CGContextSetRGBStrokeColor(ctx, colorConverted.redComponent / 1.5,
                               colorConverted.greenComponent / 1.5,
                               colorConverted.blueComponent / 1.5,
                               1.0);
    
    CGContextSetRGBFillColor(ctx, [colorConverted redComponent], [colorConverted greenComponent], [colorConverted blueComponent], [colorConverted alphaComponent]);
    
    CGRect nativeBounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    nativeBounds.origin.x++;
    nativeBounds.origin.y++;
    nativeBounds.size.width -= 2;
    nativeBounds.size.height -= 2;
    CGFloat minSide = fmin(nativeBounds.size.width, nativeBounds.size.height);
    nativeBounds.size.width = minSide;
    nativeBounds.size.height = minSide;
    nativeBounds.origin.x = (self.frame.size.width - nativeBounds.size.width) / 2;
    nativeBounds.origin.y = (self.frame.size.height - nativeBounds.size.height) / 2;
    
    {
        CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
        size_t num_locations = 2;
        CGFloat locations[2] = { 1.0, 0.0 };
        CGFloat components[8] = { [colorConverted redComponent], [colorConverted greenComponent], [colorConverted blueComponent], [colorConverted alphaComponent],
            [colorConverted redComponent], [colorConverted greenComponent], [colorConverted blueComponent], [colorConverted alphaComponent] * .5};
        
        CGPoint myStartPoint, myEndPoint;
        myStartPoint.x = nativeBounds.size.width / 2 + nativeBounds.origin.x;
        myStartPoint.y = nativeBounds.size.height / 2 + nativeBounds.origin.y;
        myEndPoint.x = nativeBounds.size.width / 2 + nativeBounds.origin.x;
        myEndPoint.y = nativeBounds.size.height / 2 + nativeBounds.origin.y;
        
        CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
        
        CGContextDrawRadialGradient(ctx, myGradient, myStartPoint, 0, myEndPoint, nativeBounds.size.width / 2, 0);
        
        CGGradientRelease(myGradient);
        CGColorSpaceRelease(myColorspace);
    }
    
    CGContextStrokeEllipseInRect(ctx, nativeBounds);

    if (self.drawHighlight == TRUE)
    {
#if 0
        CGImageRef mask = CGBitmapContextCreateImage(ctx);
        
        CGContextClipToMask(ctx, self.bounds, mask);
        
        CGFloat startXFactor = -1.25;
        CGFloat startYFactor = startXFactor;
        CGFloat widthFactor = 2.2;
        CGFloat heightFactor = widthFactor;
        
        CGRect glassBounds = CGRectMake((nativeBounds.size.width + nativeBounds.origin.x) * startXFactor,
                                        (nativeBounds.size.height + nativeBounds.origin.y) * startYFactor,
                                        (nativeBounds.size.width + nativeBounds.origin.x) * widthFactor,
                                        (nativeBounds.size.height + nativeBounds.origin.y) * heightFactor);
        CGContextSetRGBFillColor(ctx, .9, .9, .9, .5);
        CGContextFillEllipseInRect(ctx, glassBounds);
        
        CGImageRelease(mask);
#endif
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)onTick;
{
    self.state = 0;
    [self setNeedsDisplay:YES];
}

- (void)blink;
{
    self.state = 1;
    [self setNeedsDisplay:YES];
    [self performSelector:@selector(onTick) withObject:nil afterDelay:self.blinkTime];
}

- (NSColor *)onColor;
{
    return _onColor;
}

- (void)setOnColor:(NSColor *)value;
{
    _onColor = value;
    [self setNeedsDisplay:YES];
}

- (NSColor *)offColor;
{
    return _offColor;
}

- (void)setOffColor:(NSColor *)value;
{
    _offColor = value;
    [self setNeedsDisplay:YES];
}

- (CGFloat)value;
{
    return _value;
}

- (void)setValue:(CGFloat)v;
{
    _value = v;

    if (_value == 0)
    {
        self.state = FALSE;
    }
    else
    {
        self.state = TRUE;
    }
}

- (BOOL)state;
{
    return _state;
}

- (void)setState:(BOOL)value;
{
    _state = value;

    [self setNeedsDisplay:YES];
}

- (void)turnOn;
{
    self.state = 1;
}

- (void)turnOff;
{
    self.state = 0;
}

- (NSString *)description;
{
    return @"LED";
}

@end
