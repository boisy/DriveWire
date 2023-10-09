/* LogViewController */

#import <Cocoa/Cocoa.h>

@interface LogViewController : NSViewController
{
    IBOutlet NSTextView *logTextView;
}

- (IBAction)clearLog:(id)sender;
- (IBAction)copyLog:(id)sender;

- (void)updateLog:(NSString *)logString;
- (void)update:(NSDictionary *)info;

@end
