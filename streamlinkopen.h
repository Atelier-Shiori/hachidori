//
//  streamlinkopen.h
//  Hachidori
//
//  Created by 天々座理世 on 2017/03/21.
//
//

#import <Cocoa/Cocoa.h>
@class streamlinkdetector;

@interface streamlinkopen : NSWindowController{
    streamlinkdetector * detector;
}
@property (strong) IBOutlet NSTextField *streamurl;
@property (strong) IBOutlet NSButton *openstreambtn;
@property (strong) IBOutlet NSPopUpButton *streams;
- (IBAction)refreshstreams:(id)sender;
- (IBAction)openstream:(id)sender;
- (IBAction)cancel:(id)sender;

@end
