/* DriveWireDocument */

#import "VirtualDriveJukeBoxView.h"
#import "DriveWireServerModel.h"
#import "PrinterWindowController.h"
#import "DebuggerWindowController.h"
#import "LogViewController.h"
#import "StatsViewController.h"

@interface DriveWireDocument : NSDocument <DriveWireDelegate>

@property (weak) IBOutlet VirtualDriveJukeBoxView *driveView;
@property (weak) IBOutlet NSPopUpButton *serialPortButton;
@property (weak) IBOutlet NSPopUpButton *baudRatePopupButton;
@property (strong) NSWindowController *myWindowController;
@property (assign) NSInteger lastPortSelected;
@property (strong) DriveWireServerModel *server;
@property (strong) BGPLog *log;
@property (assign) IBOutlet DebuggerWindowController *debuggerWindowController;
@property (assign) IBOutlet PrinterWindowController *printerWindowController;

- (void)updateMemoryView:(NSDictionary *)info;
- (void)updateRegisterView:(NSDictionary *)info;
- (void)updatePrinterView:(NSDictionary *)info;

- (void)updateUIComponents;
- (IBAction)setCoCoType:(id)sender;
- (IBAction)setSerialPort:(id)sender;
- (void)driveNotification:(NSNotification *)note;
- (IBAction)goCoCo:(id)sender;

- (void)viewWireBugWindow:(id)sender;
- (void)viewPrinterWindow:(id)sender;

@end
