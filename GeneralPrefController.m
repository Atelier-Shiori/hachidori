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


@implementation GeneralPrefController
- (instancetype)init
{
	return [super initWithNibName:@"GeneralPreferenceView" bundle:nil];
}

// Launch at Startup Functions - http://bdunagan.com/2010/09/25/cocoa-tip-enabling-launch-on-startup/ - MIT License
- (BOOL)isLaunchAtStartup {
    // See if the app is currently in LoginItems.
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    // Store away that boolean.
    BOOL isInList = itemRef != nil;
    // Release the reference if it exists.
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

- (IBAction)toggleLaunchAtStartup:(id)sender {
    // Toggle the state.
    BOOL shouldBeToggled = ![self isLaunchAtStartup];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    if (shouldBeToggled) {
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (CFURLRef)[NSURL fileURLWithPath:[NSBundle mainBundle].bundlePath];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    }
    else {
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
    }
    CFRelease(loginItemsRef);
}

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef itemRef = nil;
    NSURL *itemUrl = nil;
    
    // Get the app's URL.
    NSURL *appUrl = [NSURL fileURLWithPath:[NSBundle mainBundle].bundlePath];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return nil;
    // Iterate over the LoginItems.
    NSArray *loginItems = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (int currentIndex = 0; currentIndex < loginItems.count; currentIndex++) {
        // Get the current LoginItem and resolve its URL.
        LSSharedFileListItemRef currentItemRef = (LSSharedFileListItemRef)loginItems[currentIndex];
        if (LSSharedFileListItemResolve(currentItemRef, 0, (CFURLRef *) &itemUrl, NULL) == noErr) {
            // Compare the URLs for the current LoginItem and the app.
            if ([itemUrl isEqual:appUrl]) {
                // Save the LoginItem reference.
                itemRef = currentItemRef;
            }
        }
    }
    // Retain the LoginItem reference.
    if (itemRef != nil) CFRetain(itemRef);
    // Release the LoginItems lists.
    [loginItems release];
    CFRelease(loginItemsRef);
    
    return itemRef;
}

#pragma mark -
#pragma mark MASPreferencesViewController
-(void)loadView{
    [super loadView];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9){
        // Disable Yosemite UI options
        [disablenewtitlebar setEnabled:NO];
        [disablevibarency setEnabled: NO];
    }
    startatlogin.state = [self isLaunchAtStartup]; // Set Launch at Startup State
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
    [allCaches release];
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
        dispatch_release(queue);
    });
    
}
-(IBAction)disableAutoExceptions:(id)sender{
    if (updateexceptionschk.state) {
        [self updateAutoExceptions:sender];
    }
    else{
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
        [alert release];
        }];
    }
}
- (IBAction)changetimerinterval:(id)sender {
    // Sets new time for the timer, if running
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    if ([delegate getisScrobbling]){
        [delegate stoptimer];
        [delegate starttimer];
    }
}
@end
