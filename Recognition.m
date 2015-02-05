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
    regex = [OGRegularExpression regularExpressionWithString: @"(S|s)\\d"];
    smatch = [regex matchInString:tmptitle];
    if (smatch != nil) {
        tmpseason = [smatch matchedString];
        regex = [OGRegularExpression regularExpressionWithString: @"(S|s)"];
        tmpseason = [regex replaceAllMatchesInString:tmpseason withString:@""];
        DetectedSeason = [tmpseason intValue];
    }
    else {
        regex = [OGRegularExpression regularExpressionWithString:@"\\d+(st|nd|rd|th)" options:OgreIgnoreCaseOption];
        smatch = [regex matchInString:tmptitle];
        if (smatch !=nil) {
            tmpseason = [smatch matchedString];
            regex = [OGRegularExpression regularExpressionWithString: @"(st|nd|rd|th)"];
            tmpseason = [regex replaceAllMatchesInString:tmpseason withString:@""];
            DetectedSeason = [tmpseason intValue];
        }
        else{
            regex = [OGRegularExpression regularExpressionWithString: @"(second|third|fourth|fifth|sixth|seventh|eighth|nineth)" options:OgreIgnoreCaseOption];
            smatch = [regex matchInString:tmptitle];
            if (smatch !=nil) {
                tmpseason = [smatch matchedString];
                DetectedSeason = [self recognizeSeason:tmpseason];
            }
            else{
                DetectedSeason = 1;
            }
        }
        
    }
    
    // Trim Whitespace
    DetectedTitle = [DetectedTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    DetectedEpisode = [DetectedEpisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [NSDictionary dictionaryWithObjectsAndKeys:DetectedTitle,@"title", DetectedEpisode, @"episode", [NSNumber numberWithInt:DetectedSeason], @"season", DetectedGroup, @"group", nil];
    
}
-(int)recognizeSeason:(NSString *)season{
    if ([season caseInsensitiveCompare:@"second"] == NSOrderedSame)
        return 2;
    else if ([season caseInsensitiveCompare:@"third"] == NSOrderedSame)
        return 3;
    else if ([season caseInsensitiveCompare:@"fourth"] == NSOrderedSame)
        return 4;
    else if ([season caseInsensitiveCompare:@"fifth"] == NSOrderedSame)
        return 5;
    else if ([season caseInsensitiveCompare:@"sixth"] == NSOrderedSame)
        return 6;
    else if ([season caseInsensitiveCompare:@"seventh"] == NSOrderedSame)
        return 7;
    else if ([season caseInsensitiveCompare:@"eighth"] == NSOrderedSame)
        return 8;
    else if ([season caseInsensitiveCompare:@"ninth"] == NSOrderedSame)
        return 9;
    else
        return 0;
}
@end