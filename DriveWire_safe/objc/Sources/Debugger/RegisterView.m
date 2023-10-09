#import "RegisterView.h"

@implementation RegisterView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
	}
   
	return self;
}

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registerNotification:)
                                                 name:@"wirebugRegisters"
                                               object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"wirebugRegisters"
                                                  object:self];
}

- (void)drawRect:(NSRect)rect
{
}

- (void)setDelegate:(id)value;
{
   _delegate = value;
}

- (id)delegate;
{
   return _delegate;
}

- (void)update:(NSDictionary *)info;
{
	u_int8_t	_cc, _dp, _a, _b, _e, _f;
	u_int16_t	_x, _y, _u, _s, _pc;
   
	_s  = [[info objectForKey:@"S"] intValue];
	_u  = [[info objectForKey:@"U"] intValue];
	_y  = [[info objectForKey:@"Y"] intValue];
	_x  = [[info objectForKey:@"X"] intValue];
	_f  = [[info objectForKey:@"F"] intValue];
	_e  = [[info objectForKey:@"E"] intValue];
	_b  = [[info objectForKey:@"B"] intValue];
	_a  = [[info objectForKey:@"A"] intValue];
	_dp = [[info objectForKey:@"DP"] intValue];
	_cc = [[info objectForKey:@"CC"] intValue];
	_pc = [[info objectForKey:@"PC"] intValue];
   
	[dp setStringValue:[NSString stringWithFormat:@"$%02X", _dp]];
	[a setStringValue:[NSString stringWithFormat:@"$%02X", _a]];
	[b setStringValue:[NSString stringWithFormat:@"$%02X", _b]];
	[e setStringValue:[NSString stringWithFormat:@"$%02X", _e]];
	[f setStringValue:[NSString stringWithFormat:@"$%02X", _f]];
	[x setStringValue:[NSString stringWithFormat:@"$%04X", _x]];
	[y setStringValue:[NSString stringWithFormat:@"$%04X", _y]];
	[u setStringValue:[NSString stringWithFormat:@"$%04X", _u]];
	[s setStringValue:[NSString stringWithFormat:@"$%04X", _s]];
	[pc setStringValue:[NSString stringWithFormat:@"$%04X", _pc]];
	
	[cc_e setState:_cc & 0x80];
}

@end
