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
typedef NS_ENUM(unsigned int, matchtype) {
    NoMatch = 0,
    PrimaryTitleMatch = 1,
    AlternateTitleMatch = 2
};
+ (int)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i;
+ (NSString *)desensitizeSeason:(NSString *)title;
+ (int)parseSeason:(NSString *)string;
+ (void)showsheetmessage:(NSString *)message
           explaination:(NSString *)explaination
                 window:(NSWindow *)w;
+ (NSString *)urlEncodeString:(NSString *)string;
+ (void)donateCheck:(AppDelegate*)delegate;
+ (void)showDonateReminder:(AppDelegate*)delegate;
+ (void)setReminderDate;
+ (void)checkDonationKey:(NSString *)key name:(NSString *)name completion:(void (^)(int success)) completionHandler;
+ (AFHTTPSessionManager*)manager;
+ (AFJSONRequestSerializer *)jsonrequestserializer;
+ (AFHTTPRequestSerializer *)httprequestserializer;
+ (AFJSONResponseSerializer *)jsonresponseserializer;
+ (AFHTTPResponseSerializer *)httpresponseserializer;
+ (int)translateKitsuTwentyScoreToMAL:(int)rating;
+ (int)translatestandardKitsuRatingtoRatingTwenty:(double)score;
+ (int)translateadvancedKitsuRatingtoRatingTwenty:(double)score;
+ (NSString *)numbertoordinal:(int)number;
+ (AFHTTPSessionManager*)jsonmanager;
+ (double)calculatedays:(NSArray *)list;
+ (NSString *)dateIntervalToDateString:(double)timeinterval;
+ (NSString *)convertAnimeType:(NSString *)type;
@end
