//
//  streamlinkopen.m
//  Hachidori
//
//  Created by 天々座理世 on 2017/03/21.
//
//

#import "streamlinkopen.h"
#import <streamlinkdetect/streamlinkdetect.h>
#import "Utility.h"

@interface streamlinkopen ()

@end

@implementation streamlinkopen
- (instancetype)init{
    self = [super initWithWindowNibName:@"streamlinkopen"];
    if(!self)
        return nil;
    return self;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    detector = [streamlinkdetector new];
    
}
- (void)controlTextDidChange:(NSNotification *)notification {
    [self refreshstreams:nil];
}
- (IBAction)refreshstreams:(id)sender {
    if (_streamurl.stringValue.length > 0) {
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            [detector setStreamURL:_streamurl.stringValue];
            NSArray * a = [detector getAvailableStreams];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_streams removeAllItems];
                [_streams addItemsWithTitles:a];
                [_streams selectItemAtIndex:[a count]-1];
            });
        });
    }
}

- (IBAction)openstream:(id)sender {
    if (_streamurl.stringValue.length == 0) {
        [Utility showsheetmessage:@"No Stream URL Entered." explaination:@"Please specify a valid stream URL and try again" window:self.window];
        return;
    }
    else if (_streams.title.length == 0) {
        [Utility showsheetmessage:@"No Stream Selected." explaination:@"Please specify a valid stream and try again" window:self.window];
        return;
    }
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:1];
}

- (IBAction)cancel:(id)sender {
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:0];
}
@end
