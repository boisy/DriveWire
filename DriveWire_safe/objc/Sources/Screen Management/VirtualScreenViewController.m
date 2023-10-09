//
//  VirtualScreenViewController.m
//  DriveWire
//
//  Created by Boisy Pitre on 4/17/15.
//
//

#import "VirtualScreenViewController.h"
#import "VirtualScreenView.h"

NSString *const kVirtualScreenUpdateNotification = @"com.drivewire.VirtualScreenUpdateNotification";

@interface VirtualScreenViewController ()

@property (strong) NSMutableData *screenBuffer;

@end


@implementation VirtualScreenViewController

- (id)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(update:)
                                                     name:kVirtualScreenUpdateNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)putCharacter:(u_char)character;
{
    VirtualScreenView *v = (VirtualScreenView *)self.view;
    [v putCharacter:character];
}


- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kVirtualScreenUpdateNotification
                                                  object:nil];
}

- (id)initWithFontURL:(NSURL *)fontURL;
{
    if (self = [super init])
    {
    }
    
    return self;
}

- (void)update:(NSNotification *)note;
{
    NSData *screenBuffer = [note.userInfo objectForKey:@"screenBuffer"];
}

@end
