//
//  DonationWindowController.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/03.
//
//

#import <Cocoa/Cocoa.h>
@class PatreonController;

@interface DonationWindowController : NSWindowController
@property (strong) IBOutlet NSTextField * name;
@property (strong) IBOutlet NSTextField * key;
@end
