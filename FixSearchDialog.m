//
//  FixSearchDialog.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 Atelier Shiori. All rights reserved.
//

#import "FixSearchDialog.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "Utility.h"

@interface FixSearchDialog ()

@end

@implementation FixSearchDialog

@synthesize arraycontroller;
@synthesize search;
@synthesize deleteoncorrection;
@synthesize onetimecorrection;
@synthesize tb;
@synthesize selectedtitle;
@synthesize selectedaniid;
@synthesize selectedtotalepisodes;
@synthesize searchquery;
@synthesize correction;
@synthesize allowdelete;

- (instancetype)init{
    self = [super initWithWindowNibName:@"FixSearchDialog"];
    if(!self)
        return nil;
    return self;
}
- (void)windowDidLoad {
    if (correction) {
        if (allowdelete) {
            [deleteoncorrection setHidden:NO];
            deleteoncorrection.state = NSOnState;
        }
        [onetimecorrection setHidden:NO];
    }
    else {
        deleteoncorrection.state = 0;
    }
    [super windowDidLoad];
    if (searchquery.length>0) {
        search.stringValue = searchquery;
        [self search:nil];
    }
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
}
- (IBAction)closesearch:(id)sender {
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:0];
}
- (IBAction)updatesearch:(id)sender {
    NSDictionary * d = arraycontroller.selectedObjects[0];
    if (correction) {
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Do you want to correct this title as %@?",nil),d[@"title"]];
        [alert setInformativeText:NSLocalizedString(@"Once done, you cannot undo this action.",nil)];
        // Set Message type to Warning
        alert.alertStyle = NSWarningAlertStyle;
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            [self finish:d];
        }
        else {
            return;
        }
    }
    else {
        [self finish:d];
    }   
}
- (void)finish:(NSDictionary *)d{
    selectedtitle = d[@"title"];
    selectedaniid = d[@"slug"];
    if (d[@"episode_count"] != [NSNull null]) {
        selectedtotalepisodes = ((NSNumber *)d[@"episode_count"]).intValue;
    }
    else {
        selectedtotalepisodes = 0;
    }
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:1];
}
- (IBAction)search:(id)sender{
    if (search.stringValue.length> 0) {
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
        NSString * searchterm = [Utility urlEncodeString:search.stringValue];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime?filter[text]=%@", searchterm]];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Perform Search
        [request startRequest];
        // Get Status Code
        long statusCode = [request getStatusCode];
        NSData *response = [request getResponseData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch (statusCode) {
                        case 200:
                            [self populateData:response];
                            break;
                        default:
                            break;
                    }
                });
                });
    }
    else {
        //Remove all existing Data
        [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    }
}
- (IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Correction-Exception-Help"]];
}
- (void)populateData:(NSData *)data{
    //Remove all existing Data
    [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    
    //Parse Data
    NSError* error;
    //Translate the Kitsu search data to old format
    NSDictionary *tmpd = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    NSArray * atmp = tmpd[@"data"];
    NSMutableArray *searchdata = [NSMutableArray new];
    for (NSDictionary * d in atmp) {
        NSDictionary * attributes = d[@"attributes"];
        [searchdata addObject:@{@"slug" : d[@"id"],@"title":attributes[@"canonicalTitle"], @"episode_count" : attributes[@"episodeCount"], @"synopsis" : attributes[@"synopsis"], @"show_type":attributes[@"showType"]}];
    }
    //Add it to the array controller
    [arraycontroller addObjects:searchdata];
    
    //Show on tableview
    [tb reloadData];
    //Deselect Selection
    [tb deselectAll:self];
}

- (bool)getdeleteTitleonCorrection{
    return (bool) deleteoncorrection.state;
}

- (bool)getcorrectonce{
    return (bool) onetimecorrection.state;
}

@end
