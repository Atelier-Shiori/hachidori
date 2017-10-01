//
//  DonationWindowController.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/03.
//
//

#import "DonationWindowController.h"
#import "Utility.h"

@interface DonationWindowController ()

@end

@implementation DonationWindowController

@synthesize name;
@synthesize key;

- (id)init{
    self = [super initWithWindowNibName:@"DonationWindow"];
    if(!self)
        return nil;
    return self;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)validate:(id)sender{
    if (name.stringValue.length > 0 && key.stringValue.length>0) {
        // Check donation key
        int success = [Utility checkDonationKey:key.stringValue name:name.stringValue];
        if (success == 1) {
            [Utility showsheetmessage:NSLocalizedString(@"Registered",nil) explaination:NSLocalizedString(@"Thank you for donating. The donation reminder will no longer appear for every two weeks when MAL Sync is enabled.",nil) window:nil];
            // Add to the preferences
            [[NSUserDefaults standardUserDefaults] setObject:name.stringValue forKey:@"donor"];
            [[NSUserDefaults standardUserDefaults] setObject:key.stringValue forKey:@"donatekey"];
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"donated"];
            //Close Window
            [self.window orderOut:self];
        }
        else if (success == 2) {
            [Utility showsheetmessage:NSLocalizedString(@"No Internet",nil) explaination:NSLocalizedString(@"Make sure you are connected to the internet and try again.",nil) window:self.window];
        }
        else {
            [Utility showsheetmessage:NSLocalizedString(@"Invalid Key",nil) explaination:NSLocalizedString(@"Please make sure you copied the name and key exactly from the email.",nil) window:self.window];
        }
    }
    else {
            [Utility showsheetmessage:NSLocalizedString(@"Missing Information",nil) explaination:NSLocalizedString(@"Please type in the name and key exactly from the email and try again.",nil) window:self.window];
    }
}

- (IBAction)cancel:(id)sender{
    [self.window orderOut:self];
}

- (IBAction)purchasedonationlicense:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://softwareateliershiori.onfastspring.com/hachidori-mal-sync-donation-license"]];

}

- (IBAction)donate:(id)sender{
    // Show Donation Page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://hachidori.ateliershiori.moe/donate/"]];
}
- (IBAction)lookupkey:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://hachidori.ateliershiori.moe/donate/lostkey.php"]];
}
@end
