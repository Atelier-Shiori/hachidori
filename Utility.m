//
//  Utility.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import <AFNetworking/AFNetworking.h>

@implementation Utility
+ (bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i{
    //Checks for matches
    if ([regex search:title].count > 0 || ([regex search:atitle] && atitle.length >0 && i==0)) {
        return true;
    }
    return false;
}
+ (NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OnigRegexp * regex = [OnigRegexp compile:@"(s)\\d" options:OnigOptionIgnorecase];
    title = [title replaceByRegexp:regex with:@""];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}
+ (void)showsheetmessage:(NSString *)message
           explaination:(NSString *)explaination
                 window:(NSWindow *)w {
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"OK",nil)];
    alert.messageText = message;
    alert.informativeText = explaination;
    // Set Message type to Warning
    alert.alertStyle = 1;
    // Show as Sheet on Preference Window
    [alert beginSheetModalForWindow:w
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:NULL];
}
+ (NSString *)urlEncodeString:(NSString *)string{
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)string,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
}
+ (void)donateCheck:(AppDelegate*)delegate{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"]) {
        [Utility setReminderDate];
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] timeIntervalSinceNow] < 0) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]) {
            int validkey = [Utility checkDonationKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"donatekey"] name:[[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
            if (validkey == 1) {
                //Reset check
                [Utility setReminderDate];
            }
            else if (validkey == 2) {
                //Try again when there is internet access
            }
            else {
                //Invalid Key
                [Utility showsheetmessage:NSLocalizedString(@"Donation Key Error",nil) explaination:NSLocalizedString(@"This key has been revoked. Please contact the author of this program or enter a valid key.",nil) window:nil];
                [Utility showDonateReminder:delegate];
                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"donated"];
            }
        }
        else {
            [Utility showDonateReminder:delegate];
        }
    }
}
+ (void)showDonateReminder:(AppDelegate*)delegate{
    // Shows Donation Reminder
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Donate",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Enter Key",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Remind Me Later",nil)];
    [alert setMessageText:NSLocalizedString(@"Please Support Hachidori",nil)];
    [alert setInformativeText:NSLocalizedString(@"We noticed that you have been using the MAL Sync functionality for a while. Although this functionality is aviliable to everyone, it cost us money to host the Unofficial MAL API to make this function possible. \r\rIf you find this function helpful, please consider making a donation. You will recieve a key to remove this message while MAL Sync is enabled.",nil)];
    [alert setShowsSuppressionButton:NO];
    // Set Message type to Warning
    alert.alertStyle = NSInformationalAlertStyle;
    long choice = [alert runModal];
    if (choice == NSAlertFirstButtonReturn) {
        // Open Donation Page
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://softwareateliershiori.onfastspring.com/hachidori-mal-sync-donation-license"]];
        [Utility setReminderDate];
    }
    else if (choice == NSAlertSecondButtonReturn) {
        // Show Add Donation Key dialog.
        [delegate enterDonationKey];
        [Utility setReminderDate];
    }
    else {
        // Surpress message for 2 weeks.
        [Utility setReminderDate];
    }
}

+ (void)setReminderDate{
    //Sets Reminder Date
    NSDate *now = [NSDate date];
    NSDate * reminderdate = [now dateByAddingTimeInterval:60*60*24*7];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"donatereminderdate"];
}
+ (int)checkDonationKey:(NSString *)key name:(NSString *)name{
    //Set Search API
    NSURL *url = [NSURL URLWithString:@"https://updates.ateliershiori.moe/keycheck/check_hachidori.php"];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    [request addFormData:name forKey:@"name"];
    [request addFormData:key forKey:@"key"];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startJSONFormRequest:EasyNSURLConnectionJsonType];
    // Get Status Code
    long statusCode = [request getStatusCode];
    if (statusCode == 200) {
        NSDictionary * d = [request.response getResponseDataJsonParsed];
        int valid = ((NSNumber *)d[@"valid"]).intValue;
        if (valid == 1) {
            // Valid Key
            return 1;
        }
        else {
            // Invalid Key
            return 0;
        }
    }
    else {
        // No Internet
        return 2;
    }
}
+ (AFHTTPSessionManager*)manager {
    static dispatch_once_t onceToken;
    static AFHTTPSessionManager *manager = nil;
    if (manager) {
        [manager.requestSerializer clearAuthorizationHeader];
        manager.requestSerializer = [Utility httprequestserializer];
        manager.responseSerializer =  [Utility jsonresponseserializer];
    }
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [Utility httprequestserializer];
        manager.responseSerializer =  [Utility jsonresponseserializer];
    });
    return manager;
}
+ (AFJSONRequestSerializer *)jsonrequestserializer {
    static dispatch_once_t jronceToken;
    static AFJSONRequestSerializer *jsonrequest = nil;
    dispatch_once(&jronceToken, ^{
        jsonrequest = [AFJSONRequestSerializer serializer];
    });
    return jsonrequest;
}
+ (AFHTTPRequestSerializer *)httprequestserializer {
    static dispatch_once_t hronceToken;
    static AFHTTPRequestSerializer *httprequest = nil;
    dispatch_once(&hronceToken, ^{
        httprequest = [AFHTTPRequestSerializer serializer];
    });
    return httprequest;
}
+ (AFJSONResponseSerializer *) jsonresponseserializer {
    static dispatch_once_t jonceToken;
    static AFJSONResponseSerializer *jsonresponse = nil;
    dispatch_once(&jonceToken, ^{
        jsonresponse = [AFJSONResponseSerializer serializer];
    });
    return jsonresponse;
}
+ (AFHTTPResponseSerializer *) httpresponseserializer {
    static dispatch_once_t honceToken;
    static AFHTTPResponseSerializer *httpresponse = nil;
    dispatch_once(&honceToken, ^{
        httpresponse = [AFHTTPResponseSerializer serializer];
    });
    return httpresponse;
}
+ (int)translateKitsuTwentyScoreToMAL:(int)rating {
    // Translates Kitsu's scoring system to MAL Scoring System
    // Awful (2-5) > 1-3, Meh (6-10) > 3-5, Good (11-15) > 6-8, Great (16-20) > 8-10
    // Advanced Ratings are rounded up.
    switch (rating) {
        case 2:
            return 1;
        case 3:
        case 4:
            return 2;
        case 5:
        case 6:
            return 3;
        case 7:
        case 8:
            return 4;
        case 9:
        case 10:
            return 5;
        case 11:
        case 12:
            return 6;
        case 13:
        case 14:
            return 7;
        case 15:
        case 16:
            return 8;
        case 17:
        case 18:
            return 9;
        case 19:
        case 20:
            return 10;
        default:
            return 0;
    }
    return 0;
}
+ (int)translatestandardKitsuRatingtoRatingTwenty:(double)score {
    if (score == 0.5) {
        return 2;
    }
    else if (score == 1) {
        return 4;
    }
    else if (score == 1.5) {
        return 6;
    }
    else if (score == 2.0) {
        return 8;
    }
    else if (score == 2.5) {
        return 10;
    }
    else if (score == 3.0) {
        return 12;
    }
    else if (score == 3.5) {
        return 14;
    }
    else if (score == 4.0) {
        return 16;
    }
    else if (score == 4.5) {
        return 18;
    }
    else if (score == 5.0) {
        return 20;
    }
    return 0;
}
+ (int)translateadvancedKitsuRatingtoRatingTwenty:(double)score {
    if (score == 1.0) {
        return 2;
    }
    else if (score == 1.5) {
        return 3;
    }
    else if (score == 2.0) {
        return 4;
    }
    else if (score == 2.5) {
        return 5;
    }
    else if (score == 3.0) {
        return 6;
    }
    else if (score == 3.5) {
        return 7;
    }
    else if (score == 4.0) {
        return 8;
    }
    else if (score == 4.5) {
        return 9;
    }
    else if (score == 5.0) {
        return 10;
    }
    else if (score == 5.5) {
        return 11;
    }
    else if (score == 6.0) {
        return 12;
    }
    else if (score == 6.5) {
        return 13;
    }
    else if (score == 7.0) {
        return 14;
    }
    else if (score == 7.5) {
        return 15;
    }
    else if (score == 8.0) {
        return 16;
    }
    else if (score == 8.5) {
        return 17;
    }
    else if (score == 9.0) {
        return 18;
    }
    else if (score == 9.5) {
        return 19;
    }
    else if (score == 10.0) {
        return 20;
    }
    return 0;
}
+ (NSString *)numbertoordinal:(int)number {
    NSString *tmpnum = [NSString stringWithFormat:@"%i", number];
    tmpnum = [tmpnum substringFromIndex:tmpnum.length-1];
    NSString *ordinal = @"";
    switch (tmpnum.intValue) {
        case 1:
            ordinal = @"st";
            break;
        case 2:
            ordinal = @"nd";
            break;
        case 3:
            ordinal = @"rd";
            break;
        case 0:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
            ordinal = @"th";
            break;
    }
    return [NSString stringWithFormat:@"%i%@", number, ordinal];
}
@end
