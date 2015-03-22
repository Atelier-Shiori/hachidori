//
//  Detection.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Detection.h"
#import "Recognition.h"
#import "EasyNSURLConnection.h"

@interface Detection()
#pragma Private Methods
-(NSDictionary *)detectStream;
-(NSDictionary *)detectPlayer;
-(bool)checkifIgnored:(NSString *)filename;
-(bool)checkifTitleIgnored:(NSString *)filename;
-(bool)checkifDirectoryIgnored:(NSString *)filename;
-(bool)checkIgnoredKeywords:(NSString *)filename;
@end

@implementation Detection
#pragma Public Methods
+(NSDictionary *)detectmedia{
    Detection * d = [[self alloc] init];
    NSDictionary * result;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]) {
        result = [d detectKodi];
        if (result != nil) {
            return result;
        }
    }
    result = [d detectPlayer];
    if (result == nil) {
        // Check Stream
        result = [d detectStream];
    }
    if (result != nil) {
        // Return results
        return result;
    }
    else{
        //Return an empty array
        return nil;
    }
}
#pragma Private Methods
-(NSDictionary *)detectPlayer{
    //Create an NSDictionary
    NSDictionary * result;
    // LSOF mplayer to get the media title and segment
    
    NSArray * player = @[@"mplayer", @"mpv", @"mplayer-mt", @"VLC", @"QuickTime Playe", @"QTKitServer", @"Kodi", @"Movist"];
    NSString *string;
    OGRegularExpression    *regex;
    for(int i = 0; i <[player count]; i++){
        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/sbin/lsof"];
        [task setArguments: @[@"-c", (NSString *)player[i], @"-F", @"n"]]; 		//lsof -c '<player name>' -Fn
        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];
        
        NSFileHandle *file;
        file = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data;
        data = [file readDataToEndOfFile];
        
        string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        if (string.length > 0){
            regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm|rm|rmvb|wmv|divx|mov|flv|mpg|3gp)$" options:OgreIgnoreCaseOption];
            //Regex time
            //Get the filename first
            NSEnumerator    *enumerator;
            enumerator = [regex matchEnumeratorInString:string];
            OGRegularExpressionMatch    *match;
            while ((match = [enumerator nextObject]) != nil) {
                string = [match matchedString];
            }
            //Check if thee file name or directory is on any ignore list
            BOOL onIgnoreList = [self checkifIgnored:string];
            BOOL invalidepisode = [self checkIgnoredKeywords:string];
            //Make sure the file name is valid, even if player is open. Do not update video files in ignored directories
            if ([regex matchInString:string] !=nil && !onIgnoreList && !invalidepisode) {
                NSDictionary *d = [[Recognition alloc] recognize:string];
                NSString * DetectedTitle = (NSString *)d[@"title"];
                NSString * DetectedEpisode = (NSString *)d[@"episode"];
                NSNumber * DetectedSeason = d[@"season"];
                NSString * DetectedGroup = (NSString *)d[@"group"];
                NSString * DetectedSource;
                // Source Detection
                switch (i) {
                    case 2:
                    DetectedSource = @"SMPlayerX";
                    break;
                    case 4:
                    case 5:
                    DetectedSource = @"Quicktime";
                    break;
                    default:
                    DetectedSource = (NSString *)player[i];
                    break;
                }
                if (DetectedTitle.length > 0) {
                    //Return result
                    result = @{@"detectedtitle": DetectedTitle, @"detectedepisode": DetectedEpisode, @"detectedseason": DetectedSeason, @"detectedsource": DetectedSource, @"group": DetectedGroup};
                    return result;
                }
            }
        }
    }
    return result;
}
-(NSDictionary *)detectStream{
    // Create Dictionary
    NSDictionary * d;
    //Set detectream Task and Run it
    NSTask *task;
    task = [[NSTask alloc] init];
    NSBundle *myBundle = [NSBundle mainBundle];
    [task setLaunchPath:[myBundle pathForResource:@"detectstream" ofType:@""]];
    
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // Reads Output
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    // Launch Task
    [task launch];
    
    // Parse Data from JSON and return dictionary
    NSData *data;
    data = [file readDataToEndOfFile];
    
    
    NSError* error;
    
    d = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (d[@"result"]  == [NSNull null]){ // Check to see if anything is playing on stream
        return nil;
    }
    else{
        NSArray * c = d[@"result"];
        NSDictionary * result = c[0];
        if ([self checkifTitleIgnored:(NSString *)result[@"title"]]) {
            return nil;
        }
        else{
            NSString * DetectedTitle = (NSString *)result[@"title"];
            NSString * DetectedEpisode = [NSString stringWithFormat:@"%@",result[@"episode"]];
            NSString * DetectedSource = [NSString stringWithFormat:@"%@ in %@", [result[@"site"] capitalizedString], result[@"browser"]];
            NSString * DetectedGroup = (NSString *)result[@"site"];
            NSNumber * DetectedSeason = (NSNumber *)result[@"season"];
            return @{@"detectedtitle": DetectedTitle, @"detectedepisode": DetectedEpisode, @"detectedseason": DetectedSeason, @"detectedsource": DetectedSource, @"group": DetectedGroup};
        }
    }
}
-(NSDictionary *)detectKodi{
    // Kodi/Plex Theater Detection
    NSString * address = [[NSUserDefaults standardUserDefaults] objectForKey:@"kodiaddress"];
    NSString * port = [[NSUserDefaults standardUserDefaults] objectForKey:@"kodiport"];
    if (address.length == 0) {
        return nil;
    }
    if (port.length == 0) {
        port = @"3005";
    }
    EasyNSURLConnection * request = [[EasyNSURLConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/jsonrpc", address,port]]];
    [request startJSONRequest:@"{\"jsonrpc\": \"2.0\", \"method\": \"Player.GetItem\", \"params\": { \"properties\": [\"title\", \"season\", \"episode\", \"showtitle\", \"tvshowid\", \"thumbnail\", \"file\", \"fanart\", \"streamdetails\"], \"playerid\": 1 }, \"id\": \"VideoGetItem\"}"];
    if (request.getStatusCode == 200) {
        NSDictionary * result;
        NSError * error = nil;
        result = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
        if (result[@"result"] != nil) {
            //Valid Result, parse title
            NSDictionary * items = result[@"result"];
            NSDictionary * item = items[@"item"];
            NSString * label = item[@"label"];
            NSDictionary * d=[[Recognition alloc] recognize:label];
            NSString * DetectedTitle = (NSString *)d[@"title"];
            NSString * DetectedEpisode = (NSString *)d[@"episode"];
            NSNumber * DetectedSeason = d[@"season"];
            NSString * DetectedGroup = @"";
            NSString * DetectedSource = @"Kodi/Plex";
            NSDictionary * output = @{@"detectedtitle": DetectedTitle, @"detectedepisode": DetectedEpisode, @"detectedseason": DetectedSeason, @"detectedsource": DetectedSource, @"group": DetectedGroup};
            return output;
        }
        else{
            // Unexpected Output or Kodi/Plex not playing anything, return nil object
            return nil;
        }
    }
    else{
        return nil;
    }
}
-(bool)checkifIgnored:(NSString *)filename{
    if ([self checkifTitleIgnored:filename] || [self checkifDirectoryIgnored:filename]) {
        return true;
    }
    return false;
}
-(bool)checkifTitleIgnored:(NSString *)filename{
    // Get filename only
    filename = [[OGRegularExpression regularExpressionWithString:@"^.+/"] replaceAllMatchesInString:filename withString:@""];
    NSArray * ignoredfilenames = [[NSUserDefaults standardUserDefaults] objectForKey:@"IgnoreTitleRules"];
    if ([ignoredfilenames count] > 0) {
        for (NSDictionary * d in ignoredfilenames) {
            NSString * rule = [NSString stringWithFormat:@"%@", d[@"rule"]];
            if ([[OGRegularExpression regularExpressionWithString:rule options:OgreIgnoreCaseOption] matchInString:filename] && rule.length !=0) { // Blank rules are infinite, thus should not be counted
                NSLog(@"Video file name is on filename ignore list.");
                return true;
            }
        }
    }
    return false;
}
-(bool)checkifDirectoryIgnored:(NSString *)filename{
    //Checks if file name or directory is on ignore list
    filename = [filename stringByReplacingOccurrencesOfString:@"n/" withString:@"/"];
    // Get only the path
    filename = [[[NSURL fileURLWithPath:filename] path] stringByDeletingLastPathComponent];
    //Check ignore directories. If on ignore directory, set onIgnoreList to true.
    NSArray * ignoredirectories = [[NSUserDefaults standardUserDefaults] objectForKey:@"ignoreddirectories"];
    if ([ignoredirectories count] > 0) {
        for (NSDictionary * d in ignoredirectories) {
            if ([filename isEqualToString:d[@"directory"]]) {
                NSLog(@"Video being played is in ignored directory");
                return true;
            }
        }
    }
    return false;
}
-(bool)checkIgnoredKeywords:(NSString *)filename{
    // Check for potentially invalid episode numbers
    filename = [filename stringByReplacingOccurrencesOfString:@"n/" withString:@"/"];
    if ([[OGRegularExpression regularExpressionWithString:@"- (OP|ED|PV|NCED)" options:OgreIgnoreCaseOption] matchInString:filename]) {
        return true;
    }
    return false;
}
@end
