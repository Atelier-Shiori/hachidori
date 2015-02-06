//
//  Recognition.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Recognition.h"

@implementation Recognition
-(NSDictionary*)recognize:(NSString *)string{
    OGRegularExpression    *regex;
    NSString * DetectedTitle;
    NSString * DetectedEpisode;
    NSString * DetectedGroup;
    int DetectedSeason;
    //Get Filename
    regex = [OGRegularExpression regularExpressionWithString:@"^.+/"];
    string = [regex replaceAllMatchesInString:string
                                   withString:@""];
    NSDictionary * d = [[anitomy_bridge new] tokenize:string];
    DetectedTitle = [d objectForKey:@"title"];
    DetectedEpisode = [d objectForKey:@"episode"];
    DetectedGroup = [d objectForKey:@"group"];
    if (DetectedGroup.length == 0) {
        DetectedGroup = @"Unknown";
    }
    //Season Checking
    NSString * tmpseason;
    NSString * tmptitle = [NSString stringWithFormat:@"%@ %@", DetectedTitle, [d objectForKey:@"season"]];
    OGRegularExpressionMatch * smatch;
    regex = [OGRegularExpression regularExpressionWithString: @"((S|s)\\d|\\d)"]; //Check the only Season Notation that Anitomy does not currently support
    smatch = [regex matchInString:tmptitle];
    if (smatch != nil) {
        tmpseason = [smatch matchedString];
        regex = [OGRegularExpression regularExpressionWithString: @"(S|s)"];
        tmpseason = [regex replaceAllMatchesInString:tmpseason withString:@""];
        DetectedSeason = [tmpseason intValue];
    }
    else {
        DetectedSeason = 1;
    }
    
    // Trim Whitespace
    DetectedTitle = [DetectedTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    DetectedEpisode = [DetectedEpisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [NSDictionary dictionaryWithObjectsAndKeys:DetectedTitle,@"title", DetectedEpisode, @"episode", [NSNumber numberWithInt:DetectedSeason], @"season", DetectedGroup, @"group", nil];
    
}
@end