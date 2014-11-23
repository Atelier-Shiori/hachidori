//
//  Recognition.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Recognition.h"

@implementation Recognition
-(NSDictionary*)recognize:(NSString *)string{
    OGRegularExpression    *regex;
    NSString * DetectedTitle;
    NSString * DetectedEpisode;
    int DetectedSeason;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseNewRecognitionEngine"]) {
        //New Method
        NSLog(@"Using New Method");
        NSDictionary * d = [[anitomy_bridge alloc] tokenize:string];
        DetectedTitle = [d objectForKey:@"title"];
        DetectedEpisode = [d objectForKey:@"episode"];
    }
    else{
        //Accented e temporary fix
        regex = [OGRegularExpression regularExpressionWithString:@"e\\\\xcc\\\\x81"];
        string = [regex replaceAllMatchesInString:string
                                   withString:@"è"];
        //Cleanup
        regex = [OGRegularExpression regularExpressionWithString:@"\\.\\w+$"];
        string = [regex replaceAllMatchesInString:string
                                   withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\[[^\\]]+\\]\\s*"];
        string = [regex replaceAllMatchesInString:string
                                   withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\([^\\)]+\\)$"];
        string = [regex replaceAllMatchesInString:string
                                   withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@"_"];
        string = [regex replaceAllMatchesInString:string
                                   withString:@" "];
        regex = [OGRegularExpression regularExpressionWithString:@"~"];
        string = [regex replaceAllMatchesInString:string
                                   withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@" - "];
        string = [regex replaceAllMatchesInString:string
                                   withString:@" "];
        // Set Title Info
        regex = [OGRegularExpression regularExpressionWithString:@"( \\-) (episode |ep |ep|e)?(\\d+)([\\w\\-! ]*)$"];
        DetectedTitle = [regex replaceAllMatchesInString:string
                                          withString:@""];
        regex = [OGRegularExpression regularExpressionWithString: @"\\b\\S\\d+$"];
        DetectedTitle = [regex replaceAllMatchesInString:DetectedTitle
                                          withString:@""];
        // Set Episode Info
        regex = [OGRegularExpression regularExpressionWithString: DetectedTitle];
        string = [regex replaceAllMatchesInString:string
                                   withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@"v[\\d]"];
        DetectedEpisode = [regex replaceAllMatchesInString:string
                                            withString:@""];
    }
    //Season
    NSString * tmpseason;
    OGRegularExpressionMatch * smatch;
    regex = [OGRegularExpression regularExpressionWithString: @"(S|s)\\d"];
    smatch = [regex matchInString:DetectedTitle];
    if (smatch != nil) {
        tmpseason = [smatch matchedString];
        regex = [OGRegularExpression regularExpressionWithString: @"(S|s)"];
        tmpseason = [regex replaceAllMatchesInString:tmpseason withString:@""];
        DetectedSeason = [tmpseason intValue];
    }
    else {
        regex = [OGRegularExpression regularExpressionWithString: @"(second season| third season|fourth season|fifth season|sixth season|seventh season|eighth season|nineth season)"];
        smatch = [regex matchInString:DetectedTitle];
        if (smatch !=nil) {
            tmpseason = [smatch matchedString];
            DetectedSeason = [self recognizeSeason:tmpseason];
        }
        else{
            DetectedSeason = 1;
        }
        
    }
    
    // Trim Whitespace
    DetectedTitle = [DetectedTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    DetectedEpisode = [DetectedEpisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [NSDictionary dictionaryWithObjectsAndKeys:DetectedTitle,@"title", DetectedEpisode, @"episode", [NSNumber numberWithInt:DetectedSeason], @"season", nil];

}
-(int)recognizeSeason:(NSString *)season{
    if ([season caseInsensitiveCompare:@"second season"] == NSOrderedSame)
        return 2;
    else if ([season caseInsensitiveCompare:@"third season"] == NSOrderedSame)
        return 3;
    else if ([season caseInsensitiveCompare:@"fourth season"] == NSOrderedSame)
        return 4;
    else if ([season caseInsensitiveCompare:@"fifth season"] == NSOrderedSame)
        return 5;
    else if ([season caseInsensitiveCompare:@"sixth season"] == NSOrderedSame)
        return 6;
    else if ([season caseInsensitiveCompare:@"seventh season"] == NSOrderedSame)
        return 7;
    else if ([season caseInsensitiveCompare:@"eighth season"] == NSOrderedSame)
        return 8;
    else if ([season caseInsensitiveCompare:@"ninth season"] == NSOrderedSame)
        return 9;
    else
        return 0;
}
@end
