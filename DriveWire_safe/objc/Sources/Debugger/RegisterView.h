#import <Cocoa/Cocoa.h>

@interface RegisterView : NSView
{
	IBOutlet NSButton *cc_e, *cc_f, *cc_h, *cc_i, *cc_n, *cc_z, *cc_v, *cc_c;
	IBOutlet NSTextField *dp;
	IBOutlet NSTextField *a;
	IBOutlet NSTextField *b;
	IBOutlet NSTextField *e;
	IBOutlet NSTextField *f;
	IBOutlet NSTextField *x;
	IBOutlet NSTextField *y;
	IBOutlet NSTextField *s;
	IBOutlet NSTextField *u;
	IBOutlet NSTextField *pc;
   
   id _delegate;
}

- (void)setDelegate:(id)value;
- (id)delegate;

- (void)update:(NSDictionary *)info;

@end
