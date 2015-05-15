//
//  AppDelegate.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "AppDelegate.h"
#import "Hachidori.h"
#import "Hachidori+Update.h"
#import "PFMoveApplication.h"
#import "Preferences.h"
#import "FixSearchDialog.h"
#import "Hotkeys.h"
#import "AutoExceptions.h"
#import "ExceptionsCache.h"
#import "Utility.h"
#import "HistoryWindow.h"

@implementation AppDelegate

@synthesize window;
@synthesize historywindowcontroller;
@synthesize updatepanel;
@synthesize fsdialog;
@synthesize managedObjectContext;
#pragma mark -
#pragma mark Initalization
/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "Hachidori" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Hachidori"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"Update History.sqlite"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:url
                                                        options:options
                                                          error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        persistentStoreCoordinator = nil;
        return nil;
    }    
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext) return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}
+ (void)initialize
{
	//Create a Dictionary
	NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
	
	// Defaults
	defaultValues[@"Token"] = @"";
	defaultValues[@"ScrobbleatStartup"] = @NO;
    defaultValues[@"setprivate"] = @NO;
    defaultValues[@"useSearchCache"] = @YES;
    defaultValues[@"exceptions"] = [[NSMutableArray alloc] init];
    defaultValues[@"ignoredirectories"] = [[NSMutableArray alloc] init];
    defaultValues[@"IgnoreTitleRules"] = [[NSMutableArray alloc] init];
    defaultValues[@"ConfirmNewTitle"] = @YES;
    defaultValues[@"ConfirmUpdates"] = @NO;
	defaultValues[@"UseAutoExceptions"] = @YES;
    defaultValues[@"enablekodiapi"] = @NO;
    defaultValues[@"RewatchEnabled"] = @YES;
    defaultValues[@"kodiaddress"] = @"";
    defaultValues[@"kodiport"] = @"3005";
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9){
            //Yosemite Specific Advanced Options
        	defaultValues[@"DisableYosemiteTitleBar"] = @NO;
        	defaultValues[@"DisableYosemiteVibrance"] = @NO;
    }
	//Register Dictionary
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults:defaultValues];
	
}
- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [NSImage imageNamed:@"hachidori-status"];
    
    //Yosemite Dark Menu Support
    [statusImage setTemplate:YES];
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:statusImage];
    
    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    
    //Sets the tooptip for our item
    [statusItem setToolTip:@"Hachidori"];
    
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Initialize haengine
    haengine = [[Hachidori alloc] init];
	[haengine setManagedObjectContext:managedObjectContext];
	// Insert code here to initialize your application
	//Check if Application is in the /Applications Folder, but not on debug releases
    #ifdef DEBUG
    #else
	PFMoveToApplicationsFolderIfNecessary();
    #endif
    // Set Defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set Notification Center Delegate
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    //Register Global Hotkey
    [self registerHotkey];
    
	// Disable Update and Share Buttons
	[updatetoolbaritem setEnabled:NO];
    [sharetoolbaritem setEnabled:NO];
    [correcttoolbaritem setEnabled:NO];
    [openAnimePage setEnabled:NO];
	// Hide Window
	[window close];
	
    //Set up Yosemite UI Enhancements
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
    {
        if ([defaults boolForKey:@"DisableYosemiteTitleBar"] != 1) {
            // OS X 10.10 code here.
            //Hide Title Bar
            self.window.titleVisibility = NSWindowTitleHidden;
            // Fix Window Size
            NSRect frame = [window frame];
            frame.size = CGSizeMake(440, 291);
            [window setFrame:frame display:YES];
         }
        if ([defaults boolForKey:@"DisableYosemiteVibrance"] != 1) {
            //Add NSVisualEffectView to Window
            [windowcontent setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
            [windowcontent setMaterial:NSVisualEffectMaterialLight];
            [windowcontent setState:NSVisualEffectStateFollowsWindowActiveState];
            [windowcontent setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
            //Make Animeinfo textview transparrent
            [animeinfooutside setDrawsBackground:NO];
            [animeinfo setBackgroundColor:[NSColor clearColor]];
        }
        else{
            [windowcontent setState:NSVisualEffectStateInactive];
            [animeinfooutside setDrawsBackground:NO];
            [animeinfo setBackgroundColor:[NSColor clearColor]];
        }
        
    }
    // Fix template images
    // There is a bug where template images are not made even if they are set in XCAssets
    NSArray *images = @[@"update", @"history", @"correct", @"Info"];
    NSImage * image;
    for (NSString *imagename in images){
            image = [NSImage imageNamed:imagename];
            [image setTemplate:YES];
    }

	// Notify User if there is no Account Info
	if ([[defaults objectForKey:@"Token"] length] == 0) {
        // First time prompt
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Welcome to Hachidori"];
        [alert setInformativeText:@"Before using this program, you need to login. Do you want to open Preferences to log in now?"];
        // Set Message type to Warning
        [alert setAlertStyle:NSInformationalAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Show Preference Window and go to Login Preference Pane
            [NSApp activateIgnoringOtherApps:YES];
            [self.preferencesWindowController showWindow:nil];
            [(MASPreferencesWindowController *)self.preferencesWindowController selectControllerAtIndex:1];
        }
	}
	// Autostart Scrobble at Startup
	if ([defaults boolForKey:@"ScrobbleatStartup"] == 1) {
		[self autostarttimer];
	}
    // Import existing Exceptions Data
    [AutoExceptions importToCoreData];
}
#pragma mark General UI Functions
- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[GeneralPrefController alloc] init];
        NSViewController *loginViewController = [[LoginPref alloc] initwithAppDelegate:self];
		NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSViewController *exceptionsViewController = [[ExceptionsPref alloc] init];
        NSViewController *hotkeyViewController = [[HotkeysPrefs alloc] init];
        NSViewController *advancedViewController = [[AdvancedPrefController alloc] init];
        NSArray *controllers = @[generalViewController, loginViewController, hotkeyViewController , exceptionsViewController, suViewController, advancedViewController];
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers];
    }
    return _preferencesWindowController;
}

-(IBAction)showPreferences:(id)sender
{
	//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
	[NSApp activateIgnoringOtherApps:YES];
	[self.preferencesWindowController showWindow:nil];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
	
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];

        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}
-(IBAction)togglescrobblewindow:(id)sender
{
	if ([window isVisible]) {
        [window close];
	} else { 
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:self]; 
	} 
}
-(IBAction)getHelp:(id)sender{
    //Show Help
 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Getting-Started"]];
}
-(IBAction)showAboutWindow:(id)sender{
    // Properly show the about window in a menu item application
    [NSApp activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
}
-(void)disableUpdateItems{
    // Disables update options to prevent erorrs
    panelactive = true;
    [statusMenu setAutoenablesItems:NO];
    [updatecorrect setAutoenablesItems:NO];
    [updatenow setEnabled:NO];
    [togglescrobbler setEnabled:NO];
    [updatedcorrecttitle setEnabled:NO];
    [updatedupdatestatus setEnabled:NO];
    [revertrewatch setEnabled:NO];
    [confirmupdate setEnabled:NO];
	[findtitle setEnabled:NO];
}
-(void)enableUpdateItems{
    // Reenables update options
    panelactive = false;
    [updatenow setEnabled:YES];
    [togglescrobbler setEnabled:YES];
    [updatedcorrecttitle setEnabled:YES];
    if (confirmupdate.hidden) {
        [updatedupdatestatus setEnabled:YES];
    }
    if (!confirmupdate.hidden && ![haengine getisNewTitle]){
        [updatedupdatestatus setEnabled:YES];
        [updatecorrect setAutoenablesItems:YES];
        [revertrewatch setEnabled:YES];
    }
    [updatecorrect setAutoenablesItems:YES];
    [statusMenu setAutoenablesItems:YES];
    [confirmupdate setEnabled:YES];
    [findtitle setEnabled:YES];
}
-(void)unhideMenus{
    //Show Last Scrobbled Title and operations */
    [seperator setHidden:NO];
    [lastupdateheader setHidden:NO];
    [updatedtitle setHidden:NO];
    [updatedepisode setHidden:NO];
    [seperator2 setHidden:NO];
    [updatecorrectmenu setHidden:NO];
    [updatedcorrecttitle setHidden:NO];
    [shareMenuItem setHidden:NO];
}
-(void)toggleScrobblingUIEnable:(BOOL)enable{
    [statusMenu setAutoenablesItems:enable];
    [updatenow setEnabled:enable];
    [togglescrobbler setEnabled:enable];
    [confirmupdate setEnabled:enable];
    [findtitle setEnabled:enable];
    [revertrewatch setEnabled:enable];
    if (!enable) {
        [updatenow setTitle:@"Updating..."];
        [self setStatusText:@"Scrobble Status: Scrobbling..."];
    }
    else{
        [updatenow setTitle:@"Update Now"];
    }
}
-(void)EnableStatusUpdating:(BOOL)enable{
	[updatecorrect setAutoenablesItems:enable];
    [updatetoolbaritem setEnabled:enable];
    [updatedupdatestatus setEnabled:enable];
    [revertrewatch setEnabled:enable];
}

#pragma mark Timer Functions

- (IBAction)toggletimer:(id)sender {
	//Check to see if a token exist
	if (![Utility checktoken]) {
        [self showNotification:@"Hachidori" message:@"Please log in with your account in Preferences before you enable scrobbling"];
    }
	else {
		if (scrobbling == FALSE) {
			[self starttimer];
			[togglescrobbler setTitle:@"Stop Scrobbling"];
            [self showNotification:@"Hachidori" message:@"Auto Scrobble is now turned on."];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
			//Set Scrobbling State to true
			scrobbling = TRUE;
		}
		else {
			[self stoptimer];
			[togglescrobbler setTitle:@"Start Scrobbling"];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Stopped"];
            [self showNotification:@"Hachidori" message:@"Auto Scrobble is now turned off."];
			//Set Scrobbling State to false
			scrobbling = FALSE;
		}
	}
	
}
-(void)autostarttimer {
	//Check to see if there is an API Key stored
	if (![Utility checktoken]) {
         [self showNotification:@"Hachidori" message:@"Unable to start scrobbling since there is no login. Please verify your login in Preferences."];
	}
	else {
		[self starttimer];
		[togglescrobbler setTitle:@"Stop Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
		//Set Scrobbling State to true
		scrobbling = TRUE;
	}
}
-(void)firetimer:(NSTimer *)aTimer {
	//Tell haengine to detect and scrobble if necessary.
	NSLog(@"Starting...");
    if (!scrobbleractive) {
        scrobbleractive = true;
        // Disable toggle scrobbler and update now menu items
        [self toggleScrobblingUIEnable:false];

    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
            // Check for latest list of Auto Exceptions automatically each week
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] != nil) {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] timeIntervalSinceNow] < -604800) {
                    // Has been 1 Week, update Auto Exceptions
                    [AutoExceptions updateAutoExceptions];
                }
            }
			else{
				// First time, populate
				[AutoExceptions updateAutoExceptions];
			}
        }
        int status;
        status = [haengine startscrobbling];
    dispatch_async(dispatch_get_main_queue(), ^{
	//Enable the Update button if a title is detected
        switch (status) { // 0 - nothing playing; 1 - same episode playing; 21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed; 
            case 0:
                [self setStatusText:@"Scrobble Status: Idle..."];
                break;
            case 1:
                [self setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
                break;
            case 2:
                [self setStatusText:@"Scrobble Status: No update needed."];
                break;
            case 3:{
                [self setStatusText:@"Scrobble Status: Please confirm update."];
                NSDictionary * userinfo = @{@"title": [haengine getLastScrobbledTitle],  @"episode": [haengine getLastScrobbledEpisode]};
                [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]] updateData:userinfo];
                break;
            }
            case 21:
            case 22:{
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                NSString * notificationmsg;
                if ([haengine getRewatching]){
                    notificationmsg = [NSString stringWithFormat:@"Rewatching %@ Episode %@",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]];
                }
                else{
                    notificationmsg = [NSString stringWithFormat:@"%@ Episode %@",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]];
                }
                [self showNotification:@"Scrobble Successful." message:notificationmsg];
                //Add History Record
                [HistoryWindow addrecord:[haengine getLastScrobbledActualTitle] Episode:[haengine getLastScrobbledEpisode] Date:[NSDate date]];
                break;
            }
            case 51:
                [self setStatusText:@"Scrobble Status: Can't find title. Retrying in 5 mins..."];
                [self showNotification:@"Couldn't find title." message:[NSString stringWithFormat:@"Click here to find %@ manually.", [haengine getFailedTitle]]];
                break;
            case 52:
            case 53:
                [self showNotification:@"Scrobble Unsuccessful." message:@"Retrying in 5 mins..."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
                break;
            case 54:
                [self showNotification:@"Scrobble Unsuccessful." message:@"Check user credentials in Preferences. You may need to login again."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. User credentials might have expired."];
                break;
            case 55:
                [self setStatusText:@"Scrobble Status: No internet connection."];
                break;
            default:
                break;
        }
            if ([haengine getSuccess] == 1) {
				[findtitle setHidden:true];
                [self setStatusMenuTitleEpisode:[haengine getLastScrobbledActualTitle] episode:[haengine getLastScrobbledEpisode]];
                if (status != 3 && [haengine getConfirmed]){
                    // Show normal info
                    [self updateLastScrobbledTitleStatus:false];
                    //Enable Update Status functions
                    [self EnableStatusUpdating:YES];
                    [confirmupdate setHidden:YES];
                    [self showRevertRewatchMenu];
                }
                else{
                    // Show that user needs to confirm update
                    [self updateLastScrobbledTitleStatus:true];
                        [confirmupdate setHidden:NO];
                    if ([haengine getisNewTitle]) {
                        // Disable Update Status functions for new and unconfirmed titles.
                        [self EnableStatusUpdating:NO];
                        [revertrewatch setHidden:YES];
                    }
					else{
                        [self EnableStatusUpdating:YES];
                        [self showRevertRewatchMenu];
					}
                }
                [sharetoolbaritem setEnabled:YES];
                [correcttoolbaritem setEnabled:YES];
                [openAnimePage setEnabled:YES];
                // Show hidden menus
                [self unhideMenus];
                NSDictionary * ainfo = [haengine getLastScrobbledInfo];
                if (ainfo !=nil) { // Checks if Hachidori already populated info about the just updated title.
                    [self showAnimeInfo:ainfo];
                    [self generateShareMenu];
                }
            }
            if (status == 51) {
                //Show option to find title
                [findtitle setHidden:false];
            }
            // Enable Menu Items
            scrobbleractive = false;
            [self toggleScrobblingUIEnable:true];
	});
    });
    }
}
-(void)starttimer {
	NSLog(@"Auto Scrobble Started.");
    timer = [NSTimer scheduledTimerWithTimeInterval:300
                                             target:self
                                           selector:@selector(firetimer:)
                                           userInfo:nil
                                            repeats:YES];
}
-(void)stoptimer {
	NSLog(@"Auto Scrobble Stopped.");
	//Stop Timer
	[timer invalidate];
}

-(IBAction)updatenow:(id)sender{
    if ([Utility checktoken]) {
        [self firetimer:nil];
    }
    else
        [self showNotification:@"Hachidori" message:@"Please log in with your account in Preferences before using this program"];
}

#pragma mark Correction
-(IBAction)showCorrectionSearchWindow:(id)sender{
    bool isVisible = [window isVisible];
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    // Check if Confirm is on for new title. If so, then disable ability to delete title.
    if ((!confirmupdate.hidden && [haengine getisNewTitle]) || !findtitle.hidden){
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:NO];
    }
    else{
        [fsdialog setCorrection:YES];
    }
    if (!findtitle.hidden) {
        //Use failed title
         [fsdialog setSearchField:[haengine getFailedTitle]];
    }
    else{
        //Get last scrobbled title
        [fsdialog setSearchField:[haengine getLastScrobbledTitle]];
    }
    if (isVisible) {
        [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
        [NSApp beginSheet:[fsdialog window]
           modalForWindow:window modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    else{
        [NSApp beginSheet:[fsdialog window]
           modalForWindow:nil modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }

}
-(void)correctionDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
            if ([[fsdialog getSelectedAniID] isEqualToString:[haengine getAniID]]) {
                NSLog(@"ID matches, correction not needed.");
            }
            else{
                BOOL correctonce = [fsdialog getcorrectonce];
				if (!findtitle.hidden) {
					 [self addtoExceptions:[haengine getFailedTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[fsdialog getSelectedTotalEpisodes]];
				}
                else if ([[haengine getLastScrobbledEpisode] intValue] == [fsdialog getSelectedTotalEpisodes]){
                    // Detected episode equals the total episodes, do not add a rule and only do a correction just once.
                    correctonce = true;
                }
				else if (!correctonce){
                    // Add to Exceptions
					 [self addtoExceptions:[haengine getLastScrobbledTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[fsdialog getSelectedTotalEpisodes]];
				}
                if([fsdialog getdeleteTitleonCorrection]){
                    if([haengine removetitle:[haengine getAniID]]){
                        NSLog(@"Removal Successful");
                    }
                }
                NSLog(@"Updating corrected title...");
                int status;
				if (!findtitle.hidden) {
					status = [haengine scrobbleagain:[haengine getFailedTitle] Episode:[haengine getFailedEpisode] correctonce:false];
				}
                else if (correctonce){
                    status = [haengine scrobbleagain:[fsdialog getSelectedTitle] Episode:[haengine getLastScrobbledEpisode] correctonce:true];
                }
				else{
                    status = [haengine scrobbleagain:[haengine getLastScrobbledTitle] Episode:[haengine getLastScrobbledEpisode] correctonce:false];
				}
					
                switch (status) {
                    case 1:
                    case 2:
                    case 21:
                    case 22:{
                        [self setStatusText:@"Scrobble Status: Correction Successful..."];
                        [self showNotification:@"Hachidori" message:@"Correction was successful"];
                        [self setStatusMenuTitleEpisode:[haengine getLastScrobbledActualTitle] episode:[haengine getLastScrobbledEpisode]];
                        [self updateLastScrobbledTitleStatus:false];
	                    if (!findtitle.hidden) {
	                        //Unhide menus and enable functions on the toolbar
	                        [self unhideMenus];
	                        [sharetoolbaritem setEnabled:YES];
	                        [correcttoolbaritem setEnabled:YES];
                            [self EnableStatusUpdating:YES];
                            [openAnimePage setEnabled:YES];
                            [self showRevertRewatchMenu];
	                    }
                        //Show Anime Correct Information
                        NSDictionary * ainfo = [haengine getLastScrobbledInfo];
                        [self showAnimeInfo:ainfo];
                        [findtitle setHidden:YES];
                        [confirmupdate setHidden:true];
						//Regenerate Share Items
						[self generateShareMenu];
                        break;
                    }
                    default:
                        [self setStatusText:@"Scrobble Status: Correction unsuccessful..."];
                        [self showNotification:@"Hachidori" message:@"Correction was not successful."];
                        break;
                }
            }
        }
        else{
        }
    fsdialog = nil;
    [self enableUpdateItems]; // Enable Update Items
    //Restart Timer
    if (scrobbling == TRUE) {
        [self starttimer];
    }
}
-(void)addtoExceptions:(NSString *)detectedtitle newtitle:(NSString *)title showid:(NSString *)showid threshold:(int)threshold{
    NSManagedObjectContext * moc = managedObjectContext;
    NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
    [allExceptions setEntity:[NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc]];
    NSError * error = nil;
    NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
    BOOL exists = false;
    for (NSManagedObject * entry in exceptions) {
        int offset = [(NSNumber *)[entry valueForKey:@"episodeOffset"] intValue];
        if ([detectedtitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]] && offset == 0) {
            exists = true;
            break;
        }
    }
    if (!exists) {
        // Add exceptions to Exceptions Entity
        [ExceptionsCache addtoExceptions:detectedtitle correcttitle:title aniid:showid threshold:threshold offset:0];
    }
    //Check if title exists in cache and then remove it
    [ExceptionsCache checkandRemovefromCache:detectedtitle];

}

#pragma mark History Window functions

-(IBAction)showhistory:(id)sender
{
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
    if (!historywindowcontroller) {
        historywindowcontroller = [[HistoryWindow alloc] init];
    }
    [[historywindowcontroller window] makeKeyAndOrderFront:nil];

}
#pragma mark StatusIconTooltip, Status Text, Last Scrobbled Title Setters


-(void)setStatusToolTip:(NSString*)toolTip
{
    [statusItem setToolTip:toolTip];
}
-(void)setStatusText:(NSString*)messagetext
{
	[ScrobblerStatus setObjectValue:messagetext];
}
-(void)setLastScrobbledTitle:(NSString*)messagetext
{
	[LastScrobbled setObjectValue:messagetext];
}
-(void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode{
    //Set New Title and Episode
    [updatedtitle setTitle:title];
    [updatedepisode setTitle:[NSString stringWithFormat:@"Episode %@", episode]];
}
-(void)updateLastScrobbledTitleStatus:(BOOL)pending{
    if (pending) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:@"Pending:"];
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Pending: %@ - Episode %@ playing from %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
        [self setStatusToolTip:[NSString stringWithFormat:@"Hachidori - %@ - %@ (Pending)",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
    }
    else{
        [updatecorrect setAutoenablesItems:YES];
        if ([haengine getRewatching]){
            [lastupdateheader setTitle:@"Rewatching:"];
            [self setLastScrobbledTitle:[NSString stringWithFormat:@"Rewatching: %@ - Episode %@ playing from %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
        }
        else{
            [lastupdateheader setTitle:@"Last Scrobbled:"];
            [self setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - Episode %@ playing from %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
        }
        [self setStatusToolTip:[NSString stringWithFormat:@"Hachidori - %@ - %@",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
    }
}

#pragma mark Getters
-(bool)getisScrobbling{
    return scrobbling;
}
-(bool)getisScrobblingActive{
    return scrobbleractive;
}
-(NSManagedObjectContext *)getObjectContext{
    return managedObjectContext;
}

#pragma mark Update Status functions

-(IBAction)updatestatus:(id)sender {
    [self showUpdateDialog:[self window]];
    [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
}
-(IBAction)updatestatusmenu:(id)sender{
    [self showUpdateDialog:nil];
}
-(void)showUpdateDialog:(NSWindow *) w{
    [NSApp activateIgnoringOtherApps:YES];
    // Show Sheet
    [NSApp beginSheet:updatepanel
       modalForWindow:w modalDelegate:self
       didEndSelector:@selector(updateDidEnd:returnCode:contextInfo:)
          contextInfo:(void *)nil];
    // Set up UI
    [showtitle setObjectValue:[haengine getLastScrobbledActualTitle]];
    [showscore setStringValue:[NSString stringWithFormat:@"%f", [haengine getScore]]];
    [episodefield setStringValue:[NSString stringWithFormat:@"%i", [haengine getCurrentEpisode]]];
    if ([haengine getTotalEpisodes]  !=0) {
        [epiformatter setMaximum:@([haengine getTotalEpisodes])];
    }
    [showstatus selectItemAtIndex:[haengine getWatchStatus]];
    [notes setString:[haengine getNotes]];
    [isPrivate setState:[haengine getPrivate]];
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
}
- (void)updateDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        // Check if Episode field is empty. If so, set it to last scrobbled episode
        NSString * tmpepisode = [episodefield stringValue];
        bool episodechanged = false;
        if (tmpepisode.length == 0) {
            tmpepisode = [NSString stringWithFormat:@"%i", [haengine getCurrentEpisode]];
        }
        if ([tmpepisode intValue] != [haengine getCurrentEpisode]) {
            episodechanged = true; // Used to update the status window
        }
        BOOL result = [haengine updatestatus:[haengine getAniID] episode:tmpepisode score:[showscore floatValue] watchstatus:[showstatus titleOfSelectedItem] notes:[[notes textStorage] string] isPrivate:(BOOL) [isPrivate state]];
        if (result){
            [self setStatusText:@"Scrobble Status: Updating of Watch Status/Score Successful."];
            if (episodechanged) {
                // Update the tooltip, menu and last scrobbled title
                [self setStatusMenuTitleEpisode:[haengine getLastScrobbledActualTitle] episode:[haengine getLastScrobbledEpisode]];
                [self updateLastScrobbledTitleStatus:false];
            }
        }
        else
            [self setStatusText:@"Scrobble Status: Unable to update Watch Status/Score."];
    }
    //If scrobbling is on, restart timer
	if (scrobbling == TRUE) {
		[self starttimer];
	}
    [self enableUpdateItems]; //Reenable update items
}

-(IBAction)closeupdatestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:0];
}
-(IBAction)updatetitlestatus:(id)sender {
	[updatepanel orderOut:self];
	[NSApp endSheet:updatepanel returnCode:1];
}

-(IBAction)revertRewatch:(id)sender{
    //Show Prompt
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert setMessageText:[NSString stringWithFormat:@"Do you want to stop rewatching %@?",[haengine getLastScrobbledTitle]]];
    [alert setInformativeText:@"This will revert the title status back to it's completed state."];
    // Set Message type to Informational
    [alert setAlertStyle:NSInformationalAlertStyle];
    if ([alert runModal]== NSAlertFirstButtonReturn) {
        // Revert title
        BOOL success = [haengine stopRewatching:[haengine getAniID]];
        if (success){
            [self showNotification:@"Hachidori" message:[NSString stringWithFormat:@"%@'s rewatch status has been reverted.", [haengine getLastScrobbledTitle]]];
        }
        else{
            [self showNotification:@"Hachidori" message:@"Rewatch revert was unsuccessful."];
        }
    }
}

#pragma mark Notification Center and Title/Update Confirmation

-(void)showNotification:(NSString *)title message:(NSString *) message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = nil;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
-(void)showConfirmationNotification:(NSString *)title message:(NSString *) message updateData:(NSDictionary *)d{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = NSUserNotificationDefaultSoundName;
    notification.userInfo = d;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}
- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([notification.title isEqualToString:@"Confirm Update"] && !confirmupdate.hidden) {
        NSString * title = (notification.userInfo)[@"title"];
        NSString * episode = (notification.userInfo)[@"episode"];
        // Only confirm update if the title and episode is the same with the last scrobbled.
        if ([[haengine getLastScrobbledTitle] isEqualToString:title] && [episode intValue] == [[haengine getLastScrobbledEpisode] intValue]) {
            //Confirm Update
            [self confirmupdate];
        }
        else{
            return;
        }
    }
    else if ([notification.title isEqualToString:@"Couldn't find title."] && !findtitle.hidden){
        //Find title
        [self showCorrectionSearchWindow:nil];
    }
}
-(IBAction)confirmupdate:(id)sender{
    [self confirmupdate];
}
-(void)confirmupdate{
    BOOL success = [haengine confirmupdate];
    if (success) {
        [self updateLastScrobbledTitleStatus:false];
        [HistoryWindow addrecord:[haengine getLastScrobbledActualTitle] Episode:[haengine getLastScrobbledEpisode] Date:[NSDate date]];
        [confirmupdate setHidden:YES];
        [self setStatusText:@"Scrobble Status: Update was successful."];
        [self showNotification:@"Hachidori" message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
        if ([haengine getisNewTitle]) {
            // Enable Update Status functions for new and unconfirmed titles.
			[self EnableStatusUpdating:YES];
        }
        [self showRevertRewatchMenu];
    }
    else{
        [self showNotification:@"Hachidori" message:@"Failed to confirm update. Please try again later."];
        [self setStatusText:@"Unable to confirm update."];
    }
}
#pragma mark Hotkeys
-(void)registerHotkey{
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceScrobbleNowShortcut handler:^{
        // Scrobble Now Global Hotkey
        if ([Utility checktoken] && !panelactive) {
            [self firetimer:nil];
        }
    }];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceShowStatusMenuShortcut handler:^{
        // Status Window Toggle Global Hotkey
        [self togglescrobblewindow:nil];
    }];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceToggleScrobblingShortcut handler:^{
        // Auto Scrobble Toggle Global Hotkey
        [self toggletimer:nil];
    }];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceConfirmUpdateShortcut handler:^{
        // Confirm Update Hotkey
        if (!confirmupdate.hidden) {
            [self confirmupdate];
        }
    }];
}

#pragma mark Misc
-(void)showAnimeInfo:(NSDictionary *)d{
    //Empty
    [animeinfo setString:@""];
    //Title
    [self appendToAnimeInfo:[NSString stringWithFormat:@"%@", d[@"title"]]];
    if (d[@"alternate_title"] != [NSNull null] && [[NSString stringWithFormat:@"%@", d[@"alternate_title"]] length] >0) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Also known as %@", d[@"alternate_title"]]];
    }
    [self appendToAnimeInfo:@""];
    //Description
    [self appendToAnimeInfo:@"Description"];
    [self appendToAnimeInfo:d[@"synopsis"]];
    //Meta Information
    [self appendToAnimeInfo:@""];
    [self appendToAnimeInfo:@"Other Information"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Start Date: %@", d[@"started_airing"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Airing Status: %@", d[@"status"]]];
    if (d[@"finished_airing"] != [NSNull null]) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Finished Airing: %@", d[@"finished_airing"]]];
    }
    if (d[@"episode_count"] != [NSNull null]){
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %@", d[@"episode_count"]]];
    }
    else{
        [self appendToAnimeInfo:@"Episodes: Unknown"];
    }
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Show Type: %@", d[@"show_type"]]];
    if (d[@"age_rating"] != [NSNull null]) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Age Rating: %@", d[@"age_rating"]]];
    }
    //Image
    NSImage * dimg = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", d[@"cover_image"]]]]; //Downloads Image
    [img setImage:dimg]; //Get the Image for the title
    // Clear Anime Info so that Hachidori won't attempt to retrieve it if the same episode and title is playing
    [haengine clearAnimeInfo];
}

- (void)appendToAnimeInfo:(NSString*)text
{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
        [[animeinfo textStorage] appendAttributedString:attr];
}
-(void)showRevertRewatchMenu{
    if ([haengine getRewatching]){
        [revertrewatch setHidden:NO];
    }
    else{
        [revertrewatch setHidden:YES];
    }
}
#pragma mark Share Services
-(void)generateShareMenu{
    //Clear Share Menu
    [shareMenu removeAllItems];
    // Workaround for Share Toolbar Item
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    [shareIcon setImage:[NSImage imageNamed:NSImageNameShareTemplate]];
    [shareIcon setHidden:YES];
    [shareIcon setTitle:@""];
    [shareMenu addItem:shareIcon];
    //Generate Items to Share
    shareItems = @[[NSString stringWithFormat:@"%@ - %@", [haengine getLastScrobbledActualTitle], [haengine getLastScrobbledEpisode] ], [NSURL URLWithString:[NSString stringWithFormat:@"http://hummingbird.me/anime/%@", [haengine getAniID]]]];
    //Get Share Services for Items
    NSArray *shareServiceforItems = [NSSharingService sharingServicesForItems:shareItems];
    //Generate Share Items and populate Share Menu
    for (NSSharingService * cservice in shareServiceforItems){
        NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:[cservice title] action:@selector(shareFromService:) keyEquivalent:@""];
        [item setRepresentedObject:cservice];
        [item setImage:[cservice image]];
        [item setTarget:self];
        [shareMenu addItem:item];
    }
}
- (IBAction)shareFromService:(id)sender{
    // Share Item
    [[sender representedObject] performWithItems:shareItems];
}
-(IBAction)showLastScrobbledInformation:(id)sender{
    //Open the anime's page on MyAnimeList in the default web browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://hummingbird.me/anime/%@", [haengine getAniID]]]];
}
@end
