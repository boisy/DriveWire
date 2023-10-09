/* StatsView */

#import <Cocoa/Cocoa.h>

@interface StatsViewController : NSViewController
{
	// Cumulative Stats
	IBOutlet NSTextField		*lastOpCode;
	IBOutlet NSTextField		*lastLSN;
	IBOutlet NSTextField		*sectorsRead;
	IBOutlet NSTextField		*sectorsWritten;
	IBOutlet NSTextField		*sectorsReRead;
	IBOutlet NSTextField		*sectorsReWritten;
	IBOutlet NSTextField		*lastGetStat;
	IBOutlet NSTextField		*lastSetStat;
	IBOutlet NSTextField		*sectorsReadOk;
	IBOutlet NSTextField		*sectorsWrittenOk;
}

- (void)update:(NSDictionary *)info;

@end
