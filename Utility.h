//
//  Utility.h
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//
//

#import <Foundation/Foundation.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>
#import "string_score.h"
#import "AppDelegate.h"

@interface Utility : NSObject
+ (bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i;
+ (NSString *)desensitizeSeason:(NSString *)title;
+ (void)showsheetmessage:(NSString *)message
           explaination:(NSString *)explaination
                 window:(NSWindow *)w;
+ (NSString *)urlEncodeString:(NSString *)string;
+ (void)donateCheck:(AppDelegate*)delegate;
+ (void)showDonateReminder:(AppDelegate*)delegate;
+ (void)setReminderDate;
+ (int)checkDonationKey:(NSString *)key name:(NSString *)name;
+ (AFHTTPSessionManager*)manager;
+ (AFJSONRequestSerializer *)jsonrequestserializer;
+ (AFHTTPRequestSerializer *)httprequestserializer;
+ (AFJSONResponseSerializer *)jsonresponseserializer;
+ (AFHTTPResponseSerializer *)httpresponseserializer;
+ (int)translateKitsuTwentyScoreToMAL:(int)rating;
+ (int)translatestandardKitsuRatingtoRatingTwenty:(double)score;
+ (int)translateadvancedKitsuRatingtoRatingTwenty:(double)score;
@end
