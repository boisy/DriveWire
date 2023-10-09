//
//  VirtualSerialTableViewController.h
//  DriveWire
//
//  Created by Boisy Pitre on 12/22/17.
//

#import <Cocoa/Cocoa.h>

@interface VirtualSerialTableViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *tableView;

@end
