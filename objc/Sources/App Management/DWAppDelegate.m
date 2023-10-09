#import "DWAppDelegate.h"
#import "PFMoveApplication.h"

@implementation DWAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
{
    // Prompt user to move to applications folder
    PFMoveToApplicationsFolderIfNecessary();
    
    // Setup Sparkle
    // Add menu item for update checking
    NSMenu *mainMenu = [NSApp mainMenu];
    NSMenu *appMenu = [[mainMenu itemAtIndex:0] submenu];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Check For Updates..." action:@selector(checkForUpdates:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [appMenu insertItem:menuItem atIndex:1];

    NSString *url = nil;
    url = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUFeedURL"];
    
    [[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:url]];
    [[SUUpdater sharedUpdater] setDelegate:self];
}


#pragma mark -
#pragma mark Sparkle Methods

- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)bundle;
{
    return YES;
}

- (void)checkForUpdates:(id)sender;
{
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}


#pragma mark -
#pragma mark Menu Methods

- (IBAction)createBlankImageAction:(id)sender
{
	NSSavePanel *panel = [NSSavePanel savePanel];

	[panel setNameFieldLabel:@"Name:"];
	[panel setTitle:[sender title]];

	if ([panel runModal] == NSFileHandlingPanelOKButton)
	{
		// We just use fopen/fclose to create the file
		NSString *filename = [[panel URL] relativePath];
		NSString *extension = [filename pathExtension];
		
		if ([extension isEqualToString:@"os9"] == NO &&
			[extension isEqualToString:@"dsk"] == NO)
		{
			filename = [filename stringByAppendingPathExtension:@"dsk"];
		}

		FILE *fp = fopen([filename cStringUsingEncoding:NSUTF8StringEncoding], "w+");

		if (fp != NULL) fclose(fp);
	}
}

@end
