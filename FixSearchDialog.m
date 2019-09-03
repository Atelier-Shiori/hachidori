//
//  FixSearchDialog.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 MAL Updater OS X Group and James Moy All rights reserved.
//

#import "FixSearchDialog.h"
#import "AtarashiiAPIListFormatKitsu.h"
#import "AtarashiiAPIListFormatAniList.h"
#import "AtarashiiAPIListFormatMAL.h"
#import "AniListConstants.h"
#import <AFNetworking/AFNetworking.h>
#import "Utility.h"

@interface FixSearchDialog ()
@property (strong) AFHTTPSessionManager *searchmanager;
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
    if (!self) {
        return nil;
    }
    // Init AFNetworking
    _searchmanager = [AFHTTPSessionManager manager];
    _searchmanager.requestSerializer = [AFJSONRequestSerializer serializer];
    _searchmanager.responseSerializer = [AFJSONResponseSerializer serializer];
    _searchmanager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"application/vnd.api+json", @"text/javascript", @"text/html", @"text/plain", nil];
    [_searchmanager.requestSerializer setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Content-Type"];
    return self;
}
- (long)currentservice {
    return [NSUserDefaults.standardUserDefaults integerForKey:@"currentservice"];
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
    selectedaniid = (NSNumber *)d[@"id"];
    if (d[@"episodes"] != [NSNull null]) {
        selectedtotalepisodes = ((NSNumber *)d[@"episodes"]).intValue;
    }
    else {
        selectedtotalepisodes = 0;
    }
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:1];
}
- (IBAction)search:(id)sender{
    if (search.stringValue.length> 0) {
        [_searchmanager.requestSerializer clearAuthorizationHeader];
        NSString *searchterm = [Utility urlEncodeString:search.stringValue];
        switch (self.currentservice) {
            case 0: {
                [_searchmanager GET:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime?filter[text]=%@", searchterm] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [self populateData:[AtarashiiAPIListFormatKitsu KitsuAnimeSearchtoAtarashii:responseObject]];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                     [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
                }];
                break;
            }
            case 1: {
                [_searchmanager POST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilisttitlesearch, @"variables" : @{@"query" : search.stringValue, @"type" : @"ANIME"}} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [self populateData:[AtarashiiAPIListFormatAniList AniListAnimeSearchtoAtarashii:responseObject]];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
                }];
                break;
            }
            case 2: {
                [_searchmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori - MyAnimeList"].accessToken] forHTTPHeaderField:@"Authorization"];
                [_searchmanager GET:@"https://api.myanimelist.net/v2/anime" parameters:@{@"q" : searchterm, @"limit" : @(25), @"fields" : @"num_episodes,status,media_type,nsfw"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [self populateData:[AtarashiiAPIListFormatMAL MALAnimeSearchtoAtarashii:responseObject]];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
                }];
            }
            default: {
                break;
            }
        }
    }
}
- (IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Correction-Exception-Help"]];
}
- (void)populateData:(id)data{
    //Remove all existing Data
    [[arraycontroller mutableArrayValueForKey:@"content"] removeAllObjects];
    //Translate the Kitsu search data to old format
    NSMutableArray *searchdata = [NSMutableArray new];
    [searchdata addObjectsFromArray:data];
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
