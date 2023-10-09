#import "StatsViewController.h"
#import "DriveWireServerModel.h"
#import "DriveWireDocument.h"

@implementation StatsViewController

- (void)viewWillAppear;
{
    [super viewWillAppear];
    DriveWireDocument *document = self.view.window.windowController.document;
    DriveWireServerModel *model = document.server;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(update:)
                                                 name:kDriveWireStatusNotification
                                               object:model];
}

- (void)viewWillDisappear;
{
    [super viewWillDisappear];
    DriveWireDocument *document = self.view.window.windowController.document;
    DriveWireServerModel *model = document.server;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kDriveWireStatusNotification
                                                  object:model];
}

- (void)drawRect:(NSRect)rect
{
}

- (void)update:(NSNotification *)note;
{
    NSDictionary *info = [note.userInfo objectForKey:@"statistics"];
    
	[lastOpCode setStringValue:[info objectForKey:@"OpCode"]];
	[lastLSN setStringValue:[info objectForKey:@"LSN"]];
	[sectorsRead setStringValue:[info objectForKey:@"ReadCount"]];
	[sectorsWritten setStringValue:[info objectForKey:@"WriteCount"]];
	[sectorsReRead setStringValue:[info objectForKey:@"ReReadCount"]];
	[sectorsReWritten setStringValue:[info objectForKey:@"ReWriteCount"]];
	[lastGetStat setStringValue:[info objectForKey:@"GetStat"]];
	[lastSetStat setStringValue:[info objectForKey:@"SetStat"]];
	
	
	// Recompute read/write success percentages

	float readSuccesses = [[info objectForKey:@"ReadCount"] intValue];
	float readFailures = [[info objectForKey:@"ReReadCount"] intValue];
	float totalReads = readSuccesses + readFailures;
	float percentage = 0.0;
	
	if (totalReads != 0)
	{
		percentage = (readSuccesses / totalReads) * 100.0;
	}
	
	[sectorsReadOk setStringValue:[NSString stringWithFormat:@"%3.3f%%", percentage]];

	float writeSuccesses = [[info objectForKey:@"WriteCount"] intValue];
	float writeFailures = [[info objectForKey:@"ReWriteCount"] intValue];
	float totalWrites = writeSuccesses + writeFailures;
	
	percentage = 0.0;
	
	if (totalWrites != 0)
	{
		percentage = (writeSuccesses / totalWrites) * 100.0;
	}
	
	[sectorsWrittenOk setStringValue:[NSString stringWithFormat:@"%3.3f%%", percentage]];
	
	return;
}

@end
