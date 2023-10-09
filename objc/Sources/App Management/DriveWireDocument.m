//
//  DriveWireDocument.m
//  DriveWire
//
//  Created by Boisy Pitre on 12/23/04.
//  Copyright __MyCompanyName__ 2004 . All rights reserved.
//

#import "DriveWireDocument.h"
#import "VirtualScreenWindowController.h"

#define MODULE_HASHTAG "DriveWireDocument"

@implementation DriveWireDocument


+ (void)initializeDefaults;
{
    NSDictionary *initialValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:FALSE], @"ApplePersistenceIgnoreState",
                                   nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialValues];
}

+ (void)initialize;
{
    if ([[self className] isEqualToString:[DriveWireDocument className]])
    {
        // Initialize our defaults right away
        [DriveWireDocument initializeDefaults];
    }
}


#pragma mark -
#pragma mark Init/Dealloc

- (id)init;
{
    if (self = [super init])
	{
		// All of our initialization is done in windowControllerDidLoadNib
        self.log = [BGPLog sharedLog];
	}

    return self;
}

- (void)dealloc;
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSMutableArray *driveArray = [self.server driveArray];
	
    [nc removeObserver:self name:kBaudRateSelectedNotification object:self.server];
    [nc removeObserver:self name:kSerialPortChangedNotification object:self.server];

	// Remove observer of printer messages
    [nc removeObserver:self.printerWindowController name:@"DWPrint" object:self.server];
    [nc removeObserver:self name:kVirtualScreenOpenedNotification object:self.server];
    [nc removeObserver:self name:kVirtualScreenClosedNotification object:self.server];

	for (int i = 0; i < [driveArray count]; i++)
	{
		// Remove ourself as an observer of cartridge insert/eject messages for each drive
		[nc removeObserver:self name:@"cartridgeWasInserted" object:[driveArray objectAtIndex:i]];
		[nc removeObserver:self name:@"cartridgeWasEjected" object:[driveArray objectAtIndex:i]];
	}
    
    [self removeWindowController:self.printerWindowController];
    [self removeWindowController:self.debuggerWindowController];
}

- (NSString *)windowNibName;
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"DriveWireDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController;
{
    int i;
    NSString *currentPort, *portTitle = nil;
	
    [aController setShouldCloseDocument:YES];
    
    self.myWindowController = aController;

    if (self.server == nil)
    {
        self.server = [[DriveWireServerModel alloc] initWithDocument:self version:DW_DEFAULT_VERSION];
        self.server.scriptingContainer = self;
    }
    
    [self.server setDelegate:self];
    
    // add our window controllers
    [self addWindowController:self.printerWindowController];
    [self addWindowController:self.debuggerWindowController];
    
    // Call super class
    [super windowControllerDidLoadNib:aController];
	
    // Request the array of ports from the Document Model	
	NSMutableDictionary *portNames = [[BGPSerialManager defaultManager] availablePorts] ;

	// Remove all items from the port button
	[self.serialPortButton removeAllItems];
	
	// Get the selected serial port, if any
	currentPort = [self.server serialPort];
   
	// Iterate through the list of names and add each to the list
	{
		NSEnumerator *e = [portNames keyEnumerator];
		NSString *n;
		
		[self.serialPortButton addItemWithTitle:@"No Device"];

		while ((n = [e nextObject]))
		{
			BGPDebug(@"%@ is available\n", n);
			[self.serialPortButton addItemWithTitle:n];
			if (currentPort != nil && [currentPort compare:n] == NSOrderedSame)
			{
				portTitle = n;
			}
		}
	}

	// Select the model's port, if not nil, else select the 0th indexed item ("No Device")
	if (portTitle == nil)
	{
		[self.serialPortButton selectItemAtIndex:0];
		self.lastPortSelected = 0;
	}
	else
	{
		[self.serialPortButton selectItemWithTitle:portTitle];
		self.lastPortSelected = [self.serialPortButton indexOfSelectedItem];
	}

	// Get the array of drives from the Document Model
	NSMutableArray *driveArray = [self.server driveArray];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	for (i = 0; i < [driveArray count]; i++)
	{
		[self.driveView addSubview:[[driveArray objectAtIndex:i] view]];

		// Add ourself as an observer of cartridge insert/eject messages for each drive
		[nc addObserver:self selector:@selector(driveNotification:) name:@"cartridgeWasInserted" object:[driveArray objectAtIndex:i]];
		[nc addObserver:self selector:@selector(driveNotification:) name:@"cartridgeWasEjected" object:[driveArray objectAtIndex:i]];
		BGPDebug(@"Observing for object: 0x%@", [driveArray objectAtIndex:i]);
	}
    
    [nc addObserver:self
           selector:@selector(screenOpened:)
               name:kVirtualScreenOpenedNotification
             object:self.server];
    
    [nc addObserver:self
           selector:@selector(screenClosed:)
               name:kVirtualScreenClosedNotification
             object:self.server];
    
    // Add the printerWindowController as an observer of print messages
    [nc addObserver:self.printerWindowController selector:@selector(updatePrintBuffer:) name:@"DWPrint" object:self.server];
    
    [self.baudRatePopupButton selectItemWithTag:self.server.baudRate];
    [self updateUIComponents];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(machineSelected:) name:kBaudRateSelectedNotification
                                               object:self.server];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(portChanged:) name:kSerialPortChangedNotification
                                               object:self.server];
}


#pragma mark DriveWire Protocol Delegate Methods

- (void)updateMemoryView:(NSDictionary *)info;
{
    [self.debuggerWindowController updateMemory:info];
}

- (void)updateRegisterView:(NSDictionary *)info;
{
    [self.debuggerWindowController updateRegisters:info];
}

- (void)updatePrinterView:(NSDictionary *)info;
{
    [self.printerWindowController updatePrintBuffer:[info objectForKey:@"PrintData"]];
}

- (void)updateUIComponents;
{
}

- (NSData *)dataRepresentationOfType:(NSString *)aType;
{
    return [NSKeyedArchiver archivedDataWithRootObject:self.server];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType;
{
	self.server = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	return YES;
}

- (IBAction)setSerialPort:(id)sender;
{
	NSString *thePort = [self.serialPortButton titleOfSelectedItem];
	
	// Ask the Document Model to open thePort
	if ([self.server setCommPort:thePort] == NO)
	{
		NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Communications Error"
											   defaultButton:@"OK"
											alternateButton:nil
												otherButton:nil
								  informativeTextWithFormat:@"The port \"%@\" failed to open.", thePort];
		
		[errorAlert runModal];
		
		[self.serialPortButton selectItemAtIndex:self.lastPortSelected];
		
		return;
	}
	
	self.lastPortSelected = [sender indexOfSelectedItem];

	[self updateChangeCount:NSChangeDone];
}

- (void)portChanged:(NSNotification *)note;
{
    BGPSerialPort *p = [[note userInfo] objectForKey:@"port"];
    if ([p isKindOfClass:[NSNull class]])
    {
        [self.serialPortButton selectItemWithTitle:@"No Device"];
    }
    else
    {
        [self.serialPortButton selectItemWithTitle:p.serviceName];
    }
    [self updateUIComponents];
}

- (void)machineSelected:(NSNotification *)note;
{
    NSUInteger tag = [[[note userInfo] objectForKey:@"baudRate"] integerValue];
    [self.baudRatePopupButton selectItemWithTag:tag];
    [self updateUIComponents];
}

- (void)driveNotification:(NSNotification *)note;
{
    [self updateChangeCount:NSChangeDone];
}

- (IBAction)setCoCoType:(NSPopUpButton *)sender;
{
    NSUInteger tag = [sender selectedTag];
    [self.server setBaudRate:tag];
   
    [self updateUIComponents];
}

- (IBAction)goCoCo:(id)sender;
{
   [self.server goCoCo];
}

- (void)viewWireBugWindow:(id)sender;
{
    [self.debuggerWindowController showWindow:self];
}

- (void)viewPrinterWindow:(id)sender;
{
    [self.printerWindowController showWindow:self];
}


#pragma mark -
#pragma mark Notification Methods

- (void)screenOpened:(NSNotification *)note;
{
    VirtualScreenWindowController *screen = [note.userInfo objectForKey:@"screen"];
    [self addWindowController:screen];
    [screen showWindow:self];
}

- (void)screenClosed:(NSNotification *)note;
{
    VirtualScreenWindowController *screen = [note.userInfo objectForKey:@"screen"];
    [screen close];
    [self removeWindowController:screen];
}


#pragma mark -
#pragma mark AppleScript Support Methods

// Conformance to the NSObject(WS4AgentPlugInScriptingContainer) informal protocol.
- (NSScriptObjectSpecifier *)objectSpecifierForModel:(DriveWireServerModel *)model;
{
    NSScriptObjectSpecifier *objectSpecifier = [self objectSpecifier];
    NSPropertySpecifier *specifier = [[NSPropertySpecifier alloc] initWithContainerSpecifier:objectSpecifier key:@"model"];
    return specifier;
}

@end
