//
//  FixSearchDialog.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 Atelier Shiori. All rights reserved.
//

#import "FixSearchDialog.h"
#import "Constants.h"

@interface FixSearchDialog ()
@property (strong) IBOutlet NSWindow *window;
@end

@implementation FixSearchDialog

-(id)init{
     if(![super initWithWindowNibName:@"FixSearchDialog"])
       return nil;
    return self;
}
- (void)windowDidLoad {
    if (correction) {
        [deleteoncorrection setHidden:NO];
    }
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
-(IBAction)closesearch:(id)sender {
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseCancel];
}
-(IBAction)updatesearch:(id)sender {
    NSDictionary * d = [[arraycontroller selectedObjects] objectAtIndex:0];
    selectedtitle = [d objectForKey:@"title"];
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseOK];
}
-(IBAction)search:(id)sender{
    if ([[search stringValue] length]> 0) {
        NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)[search stringValue],
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
        //Set Search API
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/search/anime?query=%@",@"https://hbrd-v1.p.mashape.com", searchterm]];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
        //Ignore Cookies
        [request setUseCookiePersistence:NO];
        //Set Timeout
        [request setTimeOutSeconds:15];
        //Perform Search
        [request startSynchronous];
        // Get Status Code
        int statusCode = [request responseStatusCode];
        NSData *response = [request responseData];
        switch (statusCode) {
            case 200:
                [self populateData:response];
                break;
            
            default:
                break;
        }
    }
    else{
        //Remove all existing Data
        [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    }
}
-(void)populateData:(NSData *)data{
    //Remove all existing Data
    [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    
    //Parse Data
    NSError* error;
    
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    //Add it to the array controller
    [arraycontroller addObjects:searchdata];
    
    //Show on tableview
    [tb reloadData];
    //Deselect Selection
    [tb deselectAll:self];
}
-(void)setCorrection:(BOOL)correct{
    correction = correct;
}
-(void)setSearchField:(NSString *)term{
    [search setStringValue:term];
}
-(NSString *)getSelectedTitle{
    return selectedtitle;
}
-(bool)getdeleteTitleonCorrection{
    return [deleteoncorrection state];
}

@end
