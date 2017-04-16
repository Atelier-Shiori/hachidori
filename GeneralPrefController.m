//
//  GeneralPrefController.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "GeneralPrefController.h"
#import "AppDelegate.h"
#import "AutoExceptions.h"
#import "LoginItems.h"


@implementation GeneralPrefController
- (instancetype)init
{
	return [super initWithNibName:@"GeneralPreferenceView" bundle:nil];
}
-(IBAction)toggleLaunchAtStartup:(id)sender{
    [LoginItems toggleLaunchAtStartup];
}
#pragma mark -
#pragma mark MASPreferencesViewController
-(void)loadView{
    [super loadView];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) {
        // Disable Yosemite UI options
        [disablenewtitlebar setEnabled:NO];
        [disablevibarency setEnabled: NO];
    }
    startatlogin.state = [LoginItems isLaunchAtStartup]; // Set Launch at Startup State
}
- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}
-(IBAction)clearSearchCache:(id)sender{
    // Remove All cache data from Core Data Entity
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = [delegate getObjectContext];
    NSFetchRequest * allCaches = [[NSFetchRequest alloc] init];
    allCaches.entity = [NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc];
    
    NSError * error = nil;
    NSArray * caches = [moc executeFetchRequest:allCaches error:&error];
    //error handling goes here
    for (NSManagedObject * cachentry in caches) {
        [moc deleteObject:cachentry];
    }
    error = nil;
    [moc save:&error];
}
-(IBAction)updateAutoExceptions:(id)sender{
    // Updates Auto Exceptions List
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        // In a queue, download latest Auto Exceptions JSON, disable button until done and show progress wheel
        dispatch_async(dispatch_get_main_queue(), ^{
            [updateexceptionsbtn setEnabled:NO];
            [updateexceptionschk setEnabled:NO];
            [indicator startAnimation:self];});
        [AutoExceptions updateAutoExceptions];
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator stopAnimation:self];
            [updateexceptionsbtn setEnabled:YES];
            [updateexceptionschk setEnabled:YES];
        });
    });
    
}
-(IBAction)disableAutoExceptions:(id)sender{
    if (updateexceptionschk.state) {
        [self updateAutoExceptions:sender];
    }
    else {
    // Clears Exceptions if User chooses
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert setMessageText:NSLocalizedString(@"Do you want to remove all Auto Exceptions Data?",nil)];
    [alert setInformativeText:NSLocalizedString(@"Since you are disabling Auto Exceptions, you can delete the Auto Exceptions Data. You will be able to download it again.",nil)];
    // Set Message type to Warning
    alert.alertStyle = NSWarningAlertStyle;
        [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode== NSAlertFirstButtonReturn) {
        [AutoExceptions clearAutoExceptions];
            }
        }];
    }
}
- (IBAction)changetimerinterval:(id)sender {
    // Sets new time for the timer, if running
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    if ([delegate getisScrobbling]) {
        [delegate stoptimer];
        [delegate starttimer];
    }
}
@end
