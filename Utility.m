//
//  Utility.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//
//

#import "Utility.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>

@implementation Utility
+(int)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OGRegularExpression *)regex
           option:(int)i{
    //Checks for matches
    if ([regex matchInString:title] != nil) {
        return 1;
    }
    else if([regex matchInString:atitle] != nil && atitle.length >0 && i==0){
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
+(NSString *)urlEncodeString:(NSString *)string{
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)string,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
}
+(void)donateCheck:(AppDelegate*)delegate{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] == nil){
        [Utility setReminderDate];
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"donatereminderdate"] timeIntervalSinceNow] < 0) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]){
            int validkey = [Utility checkDonationKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"donatekey"] name:[[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
            if (validkey == 1){
                //Reset check
                [Utility setReminderDate];
            }
            else if (validkey == 2){
                //Try again when there is internet access
            }
            else{
                //Invalid Key
                [Utility showsheetmessage:NSLocalizedString(@"Donation Key Error",nil) explaination:NSLocalizedString(@"This key has been revoked. Please contact the author of this program or enter a valid key.",nil) window:nil];
                [Utility showDonateReminder:delegate];
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"donated"];
            }
        }
        else{
            [Utility showDonateReminder:delegate];
        }
    }
}
+(void)showDonateReminder:(AppDelegate*)delegate{
    // Shows Donation Reminder
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Donate",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Enter Key",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Remind Me Later",nil)];
    [alert setMessageText:NSLocalizedString(@"Please Support Hachidori",nil)];
    [alert setInformativeText:NSLocalizedString(@"We noticed that you have been using the MAL Sync functionality for a while. Although this functionality is aviliable to everyone, it cost us money to host the Unofficial MAL API to make this function possible. \r\rIf you find this function helpful, please consider making a donation. You will recieve a key to remove this message while MAL Sync is enabled.",nil)];
    [alert setShowsSuppressionButton:NO];
    // Set Message type to Warning
    [alert setAlertStyle:NSInformationalAlertStyle];
    long choice = [alert runModal];
    if (choice == NSAlertFirstButtonReturn) {
        // Open Donation Page
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://hachidori.ateliershiori.moe/donate/"]];
        [Utility setReminderDate];
    }
    else if (choice == NSAlertSecondButtonReturn) {
        // Show Add Donation Key dialog.
        [delegate enterDonationKey];
        [Utility setReminderDate];
    }
    else{
        // Surpress message for 2 weeks.
        [Utility setReminderDate];
    }
}

+(void)setReminderDate{
    //Sets Reminder Date
    NSDate *now = [NSDate date];
    NSDate * reminderdate = [now dateByAddingTimeInterval:60*60*24*14];
    [[NSUserDefaults standardUserDefaults] setObject:reminderdate forKey:@"donatereminderdate"];
}
+(int)checkDonationKey:(NSString *)key name:(NSString *)name{
    //Set Search API
    NSURL *url = [NSURL URLWithString:@"https://updates.ateliershiori.moe/keycheck/check.php"];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    [request addFormData:name forKey:@"name"];
    [request addFormData:key forKey:@"key"];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startJSONFormRequest:EasyNSURLConnectionJsonType];
    // Get Status Code
    long statusCode = [request getStatusCode];
    if (statusCode == 200){
        NSError* jerror;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
        int valid = [(NSNumber *)d[@"valid"] intValue];
        if (valid == 1) {
            // Valid Key
            return 1;
        }
        else{
            // Invalid Key
            return 0;
        }
    }
    else{
        // No Internet
        return 2;
    }
    
    
}
@end
