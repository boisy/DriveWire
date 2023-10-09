//
//  VirtualScreenWindowController.m
//  DriveWire
//
//  Created by Boisy Pitre on 12/27/17.
//

#import "VirtualScreenWindowController.h"
#import "VirtualScreenView.h"

NSString *const kVirtualScreenOpenedNotification = @"com.drivewire.VirtualScreenOpenedNotification";
NSString *const kVirtualScreenClosedNotification = @"com.drivewire.VirtualScreenClosedNotification";

@interface VirtualScreenWindowController ()

@end

@implementation VirtualScreenWindowController

- (id)initWithModel:(id)model number:(NSUInteger)number port:(NSUInteger)port;
{
    if (self = [super initWithWindowNibName:@"VirtualScreenWindowController"])
    {
        self.number = number;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if (self = [super initWithCoder:coder])
    {
        self.number = [coder decodeIntegerForKey:@"number"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInteger:self.number forKey:@"number"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName;
{
    return [NSString stringWithFormat:@"Z%ld - %@", self.number, displayName];
}

- (void)putByte:(u_char)byte;
{
    VirtualScreenView *vc = (VirtualScreenView *)[[self.window.contentView subviews] objectAtIndex:0];
    [vc putCharacter:byte];
}

- (void)reset;
{
    VirtualScreenView *vc = (VirtualScreenView *)[[self.window.contentView subviews] objectAtIndex:0];
    [vc reset];
}

@end
