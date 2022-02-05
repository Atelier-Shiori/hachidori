//
//  Utility.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"
#import <AFNetworking/AFNetworking.h>
#import <DonationCheck_KeyOnly/DonationKeyVerify.h>
#import "PatreonLicenseManager.h"

@import AppCenterAnalytics;
@import AppCenterCrashes;

@implementation Utility
+ (int)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OnigRegexp *)regex
           option:(int)i{
    //Checks for matches
    if ([regex search:title].count > 0) {
        return PrimaryTitleMatch;
    }
    else if (([regex search:atitle] && atitle.length >0 && i==0)) {
        return AlternateTitleMatch;
    }
    return NoMatch;
}
+ (NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OnigRegexp * regex = [OnigRegexp compile:@"(s)\\d" options:OnigOptionIgnorecase];
    title = [title replaceByRegexp:regex with:@""];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}
+ (int)parseSeason:(NSString *)string {
    // Season Parsing
    OnigRegexp    *regex;
    OnigResult *smatch;
    NSString *tmpseason;
    regex = [OnigRegexp compile:@"((S|s|Season )\\d+|\\d+(st|nd|rd|th) Season|\\s\\d+$)" options:OnigOptionIgnorecase];
    smatch = [regex search:string];
    if (smatch.count > 0) {
        tmpseason = [smatch stringAt:0];
        regex = [OnigRegexp compile:@"((st|nd|rd|th) Season)|Season |S|s|" options:OnigOptionIgnorecase];
        tmpseason = [tmpseason replaceByRegexp:regex with:@""];
        return tmpseason.intValue;
    }
    else {
        for (int i=1; i < 11; i++) {
            NSString *seasonstring = [NSString stringWithFormat:@"%@ season", [self getSpelledOutOrdinalNumber:i]];
            if ([string localizedCaseInsensitiveContainsString:seasonstring]) {
                return i;
            }
        }
    }
    return -1;
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
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}
+ (void)donateCheck:(AppDelegate*)delegate{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"]) {
        [self setReminderDate];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"donated"]) {
        [self checkDonationKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"donatekey"] name:[[NSUserDefaults standardUserDefaults] objectForKey:@"donor"] completion:^(int success) {
            if (success == 1) {
                //Reset check
                [self setReminderDate];
            }
            else if (success == 2) {
                //Try again when there is internet access
            }
            else {
                //Invalid Key
                [self showsheetmessage:NSLocalizedString(@"Donation Key Error",nil) explaination:NSLocalizedString(@"This key has been revoked. Please contact the author of this program or enter a valid key.",nil) window:nil];
                [self showDonateReminder:delegate];
                [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"donated"];
                [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"youtubedetection"];
                [self resetAnalyticsSettings];
            }
        }];
        return;
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] timeIntervalSinceNow] < 0) {
            [self showDonateReminder:delegate];
    }
}
+ (void)showDonateReminder:(AppDelegate*)delegate{
    // Shows Donation Reminder
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Donate",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Enter Key",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Remind Me Later",nil)];
    [alert setMessageText:NSLocalizedString(@"Please Support Hachidori",nil)];
    [alert setInformativeText:NSLocalizedString(@"We noticed that you have been using Hachidori for a while. Hachidori is donationware and we rely on donations to substain the development of our programs. By donating, you can remove this message and unlock additional features.",nil)];
    [alert setShowsSuppressionButton:NO];
    // Set Message type to Warning
    alert.alertStyle = NSInformationalAlertStyle;
    long choice = [alert runModal];
    if (choice == NSAlertFirstButtonReturn) {
        // Open Donation Page
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/donate/"]];
        [self setReminderDate];
    }
    else if (choice == NSAlertSecondButtonReturn) {
        // Show Add Donation Key dialog.
        [delegate enterDonationKey];
        [self setReminderDate];
    }
    else {
        // Surpress message for 2 weeks.
        [self setReminderDate];
    }
}

+ (void)setReminderDate{
    //Sets Reminder Date
    NSDate *now = [NSDate date];
    NSDate * reminderdate = [now dateByAddingTimeInterval:60*60*24*7];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"donatereminderdate"];
}
+ (void)checkDonationKey:(NSString *)key name:(NSString *)name completion:(void (^)(int success)) completionHandler {
    if ([DonationKeyVerify checkHachidoriLicense:name withDonationKey:key] || [DonationKeyVerify checkMALULicense:name withDonationKey:key]) {
        completionHandler(1);
        return;
    }
    AFHTTPSessionManager *manager = [self jsonmanager];
    [manager POST:@"https://licensing.malupdaterosx.moe/check_hachidori.php" parameters:@{@"name" : name, @"key" : key} headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        int valid = ((NSNumber *)responseObject[@"valid"]).intValue;
        if (valid == 1) {
            // Valid Key
            /*if (responseObject[@"newlicense"]) {
                [[NSUserDefaults standardUserDefaults] setObject:responseObject[@"newlicense"] forKey:@"donatekey"];
            }
            else {
                [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"donatekey"];
            }*/
            completionHandler(1);
        }
        else {
            // Invalid Key
            completionHandler(0);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionHandler(2);
    }];
}
+ (AFHTTPSessionManager*)manager {
    static dispatch_once_t onceToken;
    static AFHTTPSessionManager *manager = nil;
    if (manager) {
        [manager.requestSerializer clearAuthorizationHeader];
        manager.requestSerializer = [self httprequestserializer];
        manager.responseSerializer =  [self jsonresponseserializer];
    }
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [self httprequestserializer];
        manager.responseSerializer =  [self jsonresponseserializer];
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
+ (AFHTTPSessionManager*)jsonmanager {
    static dispatch_once_t jsononceToken;
    static AFHTTPSessionManager *jsonmanager = nil;
    dispatch_once(&jsononceToken, ^{
        jsonmanager = [AFHTTPSessionManager manager];
        jsonmanager.requestSerializer = [AFJSONRequestSerializer serializer];
        jsonmanager.responseSerializer = [AFJSONResponseSerializer serializer];
        jsonmanager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"application/vnd.api+json", @"text/javascript", @"text/html", @"text/plain", nil];
        [jsonmanager.requestSerializer setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Content-Type"];
    });
    return jsonmanager;
}
+ (double)calculatedays:(NSArray *)list {
    double duration = 0;
    for (NSDictionary *entry in list) {
        duration += ((NSNumber *)entry[@"watched_episodes"]).integerValue * ((NSNumber *)entry[@"duration"]).intValue;
    }
    duration = (duration/60)/24;
    return duration;
}

+ (NSString *)dateIntervalToDateString:(double)timeinterval {
    NSDate *aDate = [NSDate dateWithTimeIntervalSince1970:timeinterval];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    return [dateFormatter stringFromDate:aDate];
}

+ (NSString *)convertAnimeType:(NSString *)type {
    NSString *tmpstr = type.lowercaseString;
    if ([tmpstr isEqualToString: @"tv"]||[tmpstr isEqualToString: @"ova"]||[tmpstr isEqualToString: @"ona"]) {
        tmpstr = tmpstr.uppercaseString;
    }
    else {
        tmpstr = tmpstr.capitalizedString;
        tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"Tv" withString:@"TV"];
    }
    return tmpstr;
}

+ (bool)checkBeta {
    // Check if user is using beta. If so, use the experimental Appcast branch.
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *versionString = bundle.infoDictionary[@"CFBundleShortVersionString"];
    if ([versionString containsString:@"beta"] || [versionString containsString:@"alpha"] || [versionString containsString:@"pre"] || [versionString containsString:@"rc"]) {
        NSString *betaurl = @"https://updates.malupdaterosx.moe/hachidori-beta/profileInfo.php";
        if (![[NSUserDefaults.standardUserDefaults stringForKey:@"SUFeedURL"] isEqualToString:betaurl]) {
            [NSUserDefaults.standardUserDefaults setObject:betaurl forKey:@"SUFeedURL"];
            return true;
        }
    }
    return false;
}

+ (void)patreonDonateCheck:(AppDelegate*)delegate {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [[PatreonLicenseManager sharedInstance] validateLicense:[defaults valueForKey:@"donation_name"] withLicenseKey:[defaults valueForKey:@"donation_license"] withCompletion:^(bool success, bool error) {
        if (success && !error) {
            [defaults setValue:[NSDate date] forKey:@"patreon_license_last_checked"];
        }
        else if (!success && error) {
            NSDate *lastchecked = (NSDate *)[defaults valueForKey:@"patreon_license_last_checked"];
            if (lastchecked) {
                if (lastchecked.timeIntervalSinceNow < -172800) {
                    [Utility showsheetmessage:@"Donation Key Error" explaination:@"Failed to check Patreon License within 48 hours. Please reauthorize Patreon License." window:nil];
                    [Utility deactivatePatreonLicense:delegate];
                    [Utility showDonateReminder:delegate];
                }
            }
        }
        else {
            [Utility showsheetmessage:@"Donation Key Error" explaination:@"License revoked since you are no longer an active patron. Donation features are only available for active patrons and donors." window:nil];
            [self deactivatePatreonLicense:delegate];
            [Utility showDonateReminder:delegate];
        }
    }];
}

+ (void)deactivatePatreonLicense:(AppDelegate *)delegate {
    [[PatreonLicenseManager sharedInstance] removeLicense];
    [self resetAnalyticsSettings];
}

+ (void)resetAnalyticsSettings {
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"sendanalytics"];
    [MSACCrashes setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
    [MSACAnalytics setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
}

+ (NSString *)retrieveApplicationSupportDirectory:(NSString*)append {
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSError *error;
    NSString *bundlename = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    append = [NSString stringWithFormat:@"%@/%@", bundlename, append];
    NSURL *path = [filemanager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:true error:&error];
    NSString *dir = [NSString stringWithFormat:@"%@/%@",path.path,append];
    if (![filemanager fileExistsAtPath:dir isDirectory:nil]) {
        NSError *ferror;
        bool success = [filemanager createDirectoryAtPath:dir withIntermediateDirectories:true attributes:nil error:&ferror];
        if (success && ferror == nil) {
            return dir;
        }
        return @"";
    }
    return dir;
}

/* From https://stackoverflow.com/questions/6716596/is-there-a-way-in-objective-c-to-take-a-number-and-spell-it-out/6716645 */
+ (NSString*)getSpelledOutNumber:(NSInteger)num {
    NSNumber *yourNumber = [NSNumber numberWithInt:(int)num];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterSpellOutStyle];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    return [formatter stringFromNumber:yourNumber];
}

+ (NSString*)removeLastCharOfString:(NSString*)aString {
    return [aString substringToIndex:[aString length]-1];
}

+ (NSString*)getSpelledOutOrdinalNumber:(NSInteger)num {
    NSString *spelledOutNumber = [self getSpelledOutNumber:num];

    // replace all '-'
    spelledOutNumber = [spelledOutNumber stringByReplacingOccurrencesOfString:@"-"
                                                                   withString:@" "];

    NSArray *numberParts = [spelledOutNumber componentsSeparatedByString:@" "];

    NSMutableString *output = [NSMutableString string];

    NSUInteger numberOfParts = [numberParts count];
    for (int i=0; i<numberOfParts; i++) {
        NSString *numberPart = [numberParts objectAtIndex:i];

        if ([numberPart isEqualToString:@"one"])
            [output appendString:@"first"];
        else if([numberPart isEqualToString:@"two"])
            [output appendString:@"second"];
        else if([numberPart isEqualToString:@"three"])
            [output appendString:@"third"];
        else if([numberPart isEqualToString:@"five"])
            [output appendString:@"fifth"];
        else {
            NSUInteger characterCount = [numberPart length];
            unichar lastChar = [numberPart characterAtIndex:characterCount-1];
            if (lastChar == 'y')
            {
                // check if it is the last word
                if (numberOfParts-1 == i)
                { // it is
                    [output appendString:[NSString stringWithFormat:@"%@ieth ", [self removeLastCharOfString:numberPart]]];
                }
                else
                { // it isn't
                    [output appendString:[NSString stringWithFormat:@"%@-", numberPart]];
                }
            }
            else if (lastChar == 't' || lastChar == 'e')
            {
                [output appendString:[NSString stringWithFormat:@"%@th-", [self removeLastCharOfString:numberPart]]];
            }
            else
            {
                [output appendString:[NSString stringWithFormat:@"%@th ", numberPart]];
            }
        }
    }

    // eventually remove last char
    unichar lastChar = [output characterAtIndex:[output length]-1];
    if (lastChar == '-' || lastChar == ' ')
        return [self removeLastCharOfString:output];
    else
        return output;
}
@end
