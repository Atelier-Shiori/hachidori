//
//  Utility.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"

@implementation Utility
+(int)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OGRegularExpression *)regex
           option:(int)i{
    //Checks for matches
    if ([regex matchInString:title] != nil) {
        return 1;
    }
    else if([regex matchInString:atitle] != nil && [atitle length] >0 && i==0){
        return 2;
    }
    return 0;
}
+(NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OGRegularExpression* regex = [OGRegularExpression regularExpressionWithString: @"(s)\\d" options:OgreIgnoreCaseOption];
    title = [regex replaceAllMatchesInString:title withString:@""];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}
+(void)showsheetmessage:(NSString *)message
           explaination:(NSString *)explaination
                 window:(NSWindow *)w {
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:explaination];
    // Set Message type to Warning
    [alert setAlertStyle:1];
    // Show as Sheet on Preference Window
    [alert beginSheetModalForWindow:w
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:NULL];
}
+(NSString *)urlEncodeString:(NSString *)string{
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)string,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
}

@end
