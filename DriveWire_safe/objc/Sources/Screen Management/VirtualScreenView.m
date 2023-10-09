//
//  VirtualScreenView.m
//  DriveWire
//
//  Created by Boisy Pitre on 4/17/15.
//
//

#import "VirtualScreenView.h"

@implementation VirtualScreenCharacter

- (id)initWithCharacter:(u_char)character;
{
    if (self = [super init])
    {
        self.character = character;
        self.foregroundColor = [NSColor blackColor];
        self.backgroundColor = [NSColor greenColor];
    }
    
    return self;
}

- (id)init;
{
    return [self initWithCharacter:0];
}

@end

@implementation VirtualScreenView

#define pixelXPosition(x) ((x % (int)self.screenSize.width) * charSize.width)
#define pixelYPosition(y) (self.frame.size.height - charSize.height - (row * charSize.height))

- (void)constructFontBitmapWithFont:(NSFont *)font;
{
    // compute glyph width
    self.font = font;
    NSRect glyphRect = font.boundingRectForFont;
    
    self.fontBitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                  pixelsWide:glyphRect.size.width * 256
                                                                  pixelsHigh:glyphRect.size.height
                                                               bitsPerSample:8
                                                             samplesPerPixel:4
                                                                    hasAlpha:YES
                                                                    isPlanar:NO
                                                              colorSpaceName:NSDeviceRGBColorSpace
                                                                 bytesPerRow:0
                                                                bitsPerPixel:32];
    
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:self.fontBitmap];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    
    [self.backgroundColor set];

    NSDictionary *attributes = @{NSFontAttributeName : font,
                                 NSForegroundColorAttributeName : self.fontColor,
                                 NSBackgroundColorAttributeName : self.backgroundColor,
                                 NSBaselineOffsetAttributeName : @1.0
                                 };

    for (int i = 0; i < 256; i++)
    {
        NSRect rectToDraw = NSMakeRect(i * glyphRect.size.width, 0, glyphRect.size.width, glyphRect.size.height);
        [[NSString stringWithFormat:@"%c", i] drawInRect:rectToDraw withAttributes:attributes];
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)clearDisplay;
{
    self.screen = [NSMutableArray arrayWithCapacity:self.screenSize.width * self.screenSize.height];
    for (int i = 0; i < self.screenSize.width * self.screenSize.height; i++)
    {
        VirtualScreenCharacter *c = [VirtualScreenCharacter new];
        [self.screen addObject:c];
    }
    
    self.nextCharacterPosition = NSZeroPoint;
    
    // clear screen
    if (self.screenRep == nil)
    {
        self.screenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:self.frame.size.width pixelsHigh:self.frame.size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:32];
    }
    
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:self.screenRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    
    [self.backgroundColor set];
    NSRect dirtyRect = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    NSRectFill(dirtyRect);
    
    [NSGraphicsContext restoreGraphicsState];

    [self setNeedsDisplay:YES];
}

- (void)resetScreen;
{
    self.backgroundColor = [NSColor greenColor];
    self.cursorColor = [NSColor blackColor];
    self.fontColor = [NSColor blackColor];
    self.shouldDrawCursor = TRUE;
    [self clearDisplay];
}

- (void)reset;
{
    self.screenSize = NSMakeSize(80, 24);
    self.characterProcessor = @selector(nonEscapeCharacter);
    self.incomingBuffer = [NSMutableData new];
    [self resetScreen];
    [self constructFontBitmapWithFont:[NSFont systemFontOfSize:12.0]];
}

- (void)drawCursorAtPosition:(NSUInteger)i;
{
    if (self.shouldDrawCursor == FALSE)
    {
        return;
    }
    
    if (self.screenRep == nil)
    {
        self.screenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:self.frame.size.width pixelsHigh:self.frame.size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:32];
    }
    
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:self.screenRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    
    NSSize charSize = NSMakeSize(self.frame.size.width / self.screenSize.width, self.frame.size.height / self.screenSize.height);

    // draw cursor
    NSUInteger column = self.nextCharacterPosition.x;
    NSUInteger row = self.nextCharacterPosition.y;
    NSRect rectToDraw = NSMakeRect(pixelXPosition(column), pixelYPosition(row), charSize.width, charSize.height);
    [self.cursorColor setFill];
    NSRectFill(rectToDraw);

    [NSGraphicsContext restoreGraphicsState];
}

- (void)eraseCursorAtPosition:(NSUInteger)i;
{
    if (self.screenRep == nil)
    {
        self.screenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:self.frame.size.width pixelsHigh:self.frame.size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:32];
    }
    
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:self.screenRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    
    NSSize charSize = NSMakeSize(self.frame.size.width / self.screenSize.width, self.frame.size.height / self.screenSize.height);
    
    // erase cursor
    NSUInteger column = self.nextCharacterPosition.x;
    NSUInteger row = self.nextCharacterPosition.y;
    NSRect rectToDraw = NSMakeRect(pixelXPosition(column), pixelYPosition(row), charSize.width, charSize.height);
    [self.backgroundColor setFill];
    rectToDraw = NSInsetRect(rectToDraw, -2, -2);
    NSRectFill(rectToDraw);
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawCharacterAtPosition:(NSUInteger)i
{
    if (self.screenRep == nil)
    {
        self.screenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:self.frame.size.width pixelsHigh:self.frame.size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:32];
    }
    
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:self.screenRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    
    NSSize charSize = NSMakeSize(self.frame.size.width / self.screenSize.width, self.frame.size.height / self.screenSize.height);
    VirtualScreenCharacter *c = [self.screen objectAtIndex:i];
    [c.backgroundColor setFill];
    char ch = c.character;

    NSUInteger column = i % (int)self.screenSize.width;
    NSUInteger row = i / self.screenSize.width;
    NSRect rectToDraw = NSMakeRect(pixelXPosition(column), pixelYPosition(row), charSize.width, charSize.height);
    rectToDraw = NSInsetRect(rectToDraw, -2, -2);
    NSRectFill(rectToDraw);
        
    if (ch != 0x00)
    {
#if !0
        NSDictionary *attributes = @{NSFontAttributeName : [NSFont fontWithName:@"Courier New" size:charSize.height * .8],
                                     NSForegroundColorAttributeName : c.foregroundColor,
                                     NSBackgroundColorAttributeName : c.backgroundColor,
                                     NSBaselineOffsetAttributeName : @1.0
                                     };
        [[NSString stringWithFormat:@"%c", ch] drawInRect:rectToDraw withAttributes:attributes];
#else
        NSRect sourceRect = self.font.boundingRectForFont;
        sourceRect.origin.x = ch * sourceRect.size.width;
#endif
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (id)initWithFrame:(NSRect)frame;
{
    if (self = [super initWithFrame:frame])
    {
        [self reset];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder;
{
    if (self = [super initWithCoder:decoder])
    {
        [self reset];
    }
    
    return self;
}

- (void)updateVirtualScreen:(NSRect)screenRect;
{
    // draw background color
    NSSize charSize = NSMakeSize(self.frame.size.width / self.screenSize.width, self.frame.size.height / self.screenSize.height);
    
    //    char *bytes = (char *)[self.screenBuffer bytes];
    //    for (int i = 0; i < [self.screenBuffer length]; i++)
    for (int i = 0; i < self.screenSize.width * self.screenSize.height; i++)
    {
        VirtualScreenCharacter *c = [self.screen objectAtIndex:i];
        if (i == 0)
        {
            // clear screen
            [c.backgroundColor set];
            NSRectFill(screenRect);
        }
        [c.backgroundColor setFill];
        char ch = c.character;
        if (ch != 0x00)
        {
            NSUInteger column = i % (int)self.screenSize.width;
            NSUInteger row = i / self.screenSize.width;
            NSRect rectToDraw = NSMakeRect(pixelXPosition(column), pixelYPosition(row), charSize.width, charSize.height);
            
            NSRectFill(rectToDraw);
            
            NSDictionary *attributes = @{NSFontAttributeName : [NSFont fontWithName:@"Courier New" size:10.0],
                                         NSForegroundColorAttributeName : c.foregroundColor,
                                         NSBackgroundColorAttributeName : c.backgroundColor,
                                         NSBaselineOffsetAttributeName : @1.0
                                         };
            [[NSString stringWithFormat:@"%c", ch] drawInRect:rectToDraw withAttributes:attributes];
        }
    }
    
    // draw cursor
    NSUInteger column = self.nextCharacterPosition.x;
    NSUInteger row = self.nextCharacterPosition.y;
    NSRect rectToDraw = NSMakeRect(pixelXPosition(column), pixelYPosition(row), charSize.width, charSize.height);
    [self.cursorColor setFill];
    NSRectFill(rectToDraw);
}

- (void)drawRect:(NSRect)dirtyRect;
{
    if (self.screenRep)
    {
        [self.screenRep drawInRect:self.bounds];
    }
}

- (void)incrementYPosition;
{
    CGFloat x = 0.0;
    CGFloat y = self.nextCharacterPosition.y;

    // handle CR
    y++;
    if (y >= self.screenSize.height)
    {
        y = self.screenSize.height - 1;
        
        // scroll time
        // copy everything up
#if 0
        char *bytes = (char *)[self.screenBuffer bytes];
        int lineWidth = self.screenSize.width;
        char *secondLine = &bytes[lineWidth];
        int bytesToCopy = self.screenSize.width * (self.screenSize.height - 1);
        char *lastLine = &bytes[bytesToCopy];
        memcpy(bytes, secondLine, bytesToCopy);
        memset(lastLine, 0, self.screenSize.width);
#endif
        
    }
    self.nextCharacterPosition = NSMakePoint(x, y);
}

- (void)incrementXPosition;
{
    CGFloat x = self.nextCharacterPosition.x;

    x++;
    if (x >= self.screenSize.width)
    {
        x = 0;
        self.nextCharacterPosition = NSMakePoint(x, self.nextCharacterPosition.y);
        [self incrementYPosition];
    }
    else
    {
        self.nextCharacterPosition = NSMakePoint(x, self.nextCharacterPosition.y);
    }
}

- (void)putCharacter:(u_char)character;
{
    self.nextByte = character;
    [self performSelector:self.characterProcessor withObject:nil];
}

- (void)nonEscapeCharacter;
{
    NSUInteger location = self.nextCharacterPosition.y * self.screenSize.width + self.nextCharacterPosition.x;
    
    if (self.nextByte >= 0x20)
    {
        VirtualScreenCharacter *ch = [self.screen objectAtIndex:location];
        ch.foregroundColor = self.fontColor;
        ch.backgroundColor = self.backgroundColor;
        ch.character = self.nextByte;
        [self drawCharacterAtPosition:location];
        [self incrementXPosition];
        location = self.nextCharacterPosition.y * self.screenSize.width + self.nextCharacterPosition.x;
        [self drawCursorAtPosition:location];
        [self setNeedsDisplay:YES];
    }
    else
    {
        switch (self.nextByte)
        {
            case 0x05:
                self.characterProcessor = @selector(hex05_1Character);
                break;
                
            case 0x0C:
                [self clearDisplay];
                break;
                
            case 0x0D:
                [self eraseCursorAtPosition:location];
                [self incrementYPosition];
                [self drawCursorAtPosition:location];
                [self setNeedsDisplay:YES];
                break;
                
            case 0x1B:
                // start processing escape codes
                self.characterProcessor = @selector(escape1Character);
                break;

            case 0x0A:
                break; // ignore

            default:
                break;
        }
    }
}

/* display 1b 20 2 0 0 50 18 20 3 1 */
- (void)dwsetType;
{
    self.characterProcessor = @selector(dwsetX);
}

- (void)dwsetX;
{
    self.characterProcessor = @selector(dwsetY);
}

- (void)dwsetY;
{
    self.characterProcessor = @selector(dwsetWidth);
}

- (void)dwsetWidth;
{
    self.characterProcessor = @selector(dwsetHeight);
}

- (void)dwsetHeight;
{
    self.characterProcessor = @selector(dwsetForeground);
}

- (void)dwsetForeground;
{
    self.characterProcessor = @selector(dwsetBackground);
}

- (void)dwsetBackground;
{
    self.characterProcessor = @selector(dwsetBorder);
}

- (void)dwsetBorder;
{
    self.characterProcessor = @selector(nonEscapeCharacter);
}

- (void)hex05_1Character;
{
    // character following 05
    switch (self.nextByte)
    {
        case 0x20:
            self.shouldDrawCursor = FALSE;
            break;

        case 0x21:
            self.shouldDrawCursor = TRUE;
            break;
    }

    self.characterProcessor = @selector(nonEscapeCharacter);
}
            
- (void)escape1Character;
{
    // character following 1b
    switch (self.nextByte)
    {
        case 0x20:
            self.characterProcessor = @selector(dwsetType);
            break;
            
        case 0x24:
            [self resetScreen];
            self.characterProcessor = @selector(nonEscapeCharacter);
            break;
            
        case 0x32:
            self.characterProcessor = @selector(screenForegroundColor);
            break;
            
        case 0x33:
            self.characterProcessor = @selector(screenBackgroundColor);
            break;
            
        case 0x34:
            self.characterProcessor = @selector(screenBorderColor);
            break;
            
        default:
            self.characterProcessor = @selector(nonEscapeCharacter);
            break;
    }
}

- (NSColor *)colorForCode:(NSUInteger)code;
{
    NSColor *result = nil;
    
    switch (self.nextByte & 0x07)
    {
        case 0x00:
            result = [NSColor whiteColor];
            break;
            
        case 0x01:
            result = [NSColor blueColor];
            break;
            
        case 0x02:
            result = [NSColor blackColor];
            break;
            
        case 0x03:
            result = [NSColor greenColor];
            break;
            
        case 0x04:
            result = [NSColor redColor];
            break;
            
        case 0x05:
            result = [NSColor yellowColor];
            break;
            
        case 0x06:
            result = [NSColor magentaColor];
            break;
            
        case 0x07:
            result = [NSColor cyanColor];
            break;
            
        default:
            result = [NSColor blackColor];
    }
    
    return result;
}

- (void)screenForegroundColor;
{
    self.fontColor = [self colorForCode:self.nextByte];
    [self setNeedsDisplay:YES];
    self.characterProcessor = @selector(nonEscapeCharacter);
}

- (void)screenBackgroundColor;
{
    self.backgroundColor = [self colorForCode:self.nextByte];
    [self setNeedsDisplay:YES];
    self.characterProcessor = @selector(nonEscapeCharacter);
}

- (void)screenBorderColor;
{
    self.characterProcessor = @selector(nonEscapeCharacter);
}

- (BOOL)acceptsFirstResponder;
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
    NSString  *characters = [theEvent characters];
    char  c = [characters characterAtIndex: 0];
    [self.incomingBuffer appendBytes:&c length:1];
}

- (NSUInteger)availableToRead;
{
    return [self.incomingBuffer length];
}

- (u_char)getByte;
{
    u_char result = 0;
    
    result = *(u_char *)[self.incomingBuffer bytes];
    [self.incomingBuffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:nil length:0];
    
    return result;
}

@end

