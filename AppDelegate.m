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
#import "Hachidori+Keychain.h"
#import "Hachidori+MALSync.h"
#import "OfflineViewQueue.h"
#import "PFMoveApplication.h"
#import "Preferences.h"
#import "FixSearchDialog.h"
#import "Hotkeys.h"
#import "AutoExceptions.h"
#import "ExceptionsCache.h"
#import "Utility.h"
#import "HistoryWindow.h"
#import "DonationWindowController.h"
#import "MSWeakTimer.h"
#import "ClientConstants.h"
#import "streamlinkopen.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

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
    NSString *basePath = (paths.count > 0) ? paths[0] : NSTemporaryDirectory();
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
	
    NSManagedObjectModel *mom = self.managedObjectModel;
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
                                                          error:&error]) {
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
	
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = coordinator;
	
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
    defaultValues[@"MALAPIURL"] = @"https://malapi.ateliershiori.moe";
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
            //Yosemite Specific Advanced Options
        	defaultValues[@"DisableYosemiteTitleBar"] = @NO;
        	defaultValues[@"DisableYosemiteVibrance"] = @NO;
    }
    defaultValues[@"timerinterval"] = @(300);
    defaultValues[@"showcorrection"] = @YES;
    defaultValues[@"NSApplicationCrashOnExceptions"] = @YES;
	//Register Dictionary
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults:defaultValues];
}
- (void) awakeFromNib{
    // Register queue
    _privateQueue = dispatch_queue_create("moe.ateliershiori.Hachidori", DISPATCH_QUEUE_CONCURRENT);
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [NSImage imageNamed:@"hachidori-status"];
    
    //Yosemite Dark Menu Support
    [statusImage setTemplate:YES];
    
    //Sets the images in our NSStatusItem
    statusItem.image = statusImage;
    
    //Tells the NSStatusItem what menu to load
    statusItem.menu = statusMenu;
    
    //Sets the tooptip for our item
    [statusItem setToolTip:NSLocalizedString(@"Hachidori",nil)];
    
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Initialize haengine
    haengine = [[Hachidori alloc] init];
	[haengine setManagedObjectContext:managedObjectContext];
    if (floor(NSAppKitVersionNumber) < 1485) {
    #ifdef DEBUG
    #else
        // Check if Application is in the /Applications Folder
        // Only Activate in OS X/macOS is 10.11 or earlier due to Gatekeeper changes in macOS Sierra
        // Note: Sierra Appkit Version is 1485
        PFMoveToApplicationsFolderIfNecessary();
    #endif
    }
    // Set Defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set Notification Center Delegate
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
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
            NSRect frame = window.frame;
            frame.size = CGSizeMake(440, 291);
            [window setFrame:frame display:YES];
         }
        if ([defaults boolForKey:@"DisableYosemiteVibrance"] != 1) {
            //Add NSVisualEffectView to Window
            windowcontent.blendingMode = NSVisualEffectBlendingModeBehindWindow;
            windowcontent.material = NSVisualEffectMaterialLight;
            windowcontent.state = NSVisualEffectStateFollowsWindowActiveState;
            windowcontent.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            //Make Animeinfo textview transparrent
            [animeinfooutside setDrawsBackground:NO];
            animeinfo.backgroundColor = [NSColor clearColor];
        }
        else {
            windowcontent.state = NSVisualEffectStateInactive;
            [animeinfooutside setDrawsBackground:NO];
            animeinfo.backgroundColor = [NSColor clearColor];
        }
        
    }
    // Fix template images
    // There is a bug where template images are not made even if they are set in XCAssets
    NSArray *images = @[@"update", @"history", @"correct", @"Info", @"clear"];
    NSImage * image;
    for (NSString *imagename in images) {
            image = [NSImage imageNamed:imagename];
            [image setTemplate:YES];
    }

	// Notify User if there is no Account Info
	if (![haengine getFirstAccount]) {
        // First time prompt
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        [alert setMessageText:NSLocalizedString(@"Welcome to Hachidori",nil)];
        [alert setInformativeText:NSLocalizedString(@"Before using this program, you need to add an account. Do you want to open Preferences to authenticate an account now? \r\rPlease note that Hachidori has transitioned to Kitsu and therefore, you must reauthenticate.",nil)];
        // Set Message type to Warning
        alert.alertStyle = NSInformationalAlertStyle;
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
    [Fabric with:@[[Crashlytics class]]];
}
#pragma mark General UI Functions
- (NSWindowController *)preferencesWindowController
{
    if (!_preferencesWindowController)
    {
        NSViewController *generalViewController = [[GeneralPrefController alloc] init];
        NSViewController *loginViewController = [[LoginPref alloc] initwithAppDelegate:self];
		NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSViewController *exceptionsViewController = [[ExceptionsPref alloc] init];
        NSViewController *hotkeyViewController = [[HotkeysPrefs alloc] init];
        NSViewController *advancedViewController = [[AdvancedPrefController alloc] initwithAppDelegate:self];
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
	
    if (!managedObjectContext.hasChanges) return NSTerminateNow;
	
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
        alert.messageText = question;
        alert.informativeText = info;
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];

        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}
-(IBAction)togglescrobblewindow:(id)sender
{
	if (window.visible) {
        [window close];
	} else { 
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:self]; 
	} 
}
-(IBAction)showOfflineQueue:(id)sender{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_owindow) {
        _owindow = [[OfflineViewQueue alloc] init];
    }
    [[_owindow window] makeKeyAndOrderFront:nil];
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
    [openstream setEnabled:NO];
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
    if (!confirmupdate.hidden && ![haengine getisNewTitle]) {
        [updatedupdatestatus setEnabled:YES];
        [updatecorrect setAutoenablesItems:YES];
        [revertrewatch setEnabled:YES];
    }
    [updatecorrect setAutoenablesItems:YES];
    [statusMenu setAutoenablesItems:YES];
    [confirmupdate setEnabled:YES];
    [findtitle setEnabled:YES];
    [openstream setEnabled:YES];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        ForceMALSync.enabled = enable;
        statusMenu.autoenablesItems = enable;
        updatenow.enabled = enable;
        togglescrobbler.enabled = enable;
        confirmupdate.enabled = enable;
        findtitle.enabled = enable;
        revertrewatch.enabled = enable;
        openstream.enabled = enable;
        if (!enable) {
            [updatenow setTitle:NSLocalizedString(@"Updating...",nil)];
            [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobbling...",nil)];
        }
        else {
            [updatenow setTitle:NSLocalizedString(@"Update Now",nil)];
        }
    });
}
-(void)EnableStatusUpdating:(BOOL)enable{
    ForceMALSync.enabled = enable;
	updatecorrect.autoenablesItems = enable;
    updatetoolbaritem.enabled = enable;
    updatedupdatestatus.enabled = enable;
    revertrewatch.enabled = enable;
}
-(void)enterDonationKey{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_dwindow) {
        _dwindow = [[DonationWindowController alloc] init];
    }
    [[_dwindow window] makeKeyAndOrderFront:nil];
    
}
-(void)performsendupdatenotification:(int)status{
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
                if ([haengine getRewatching]) {
                    notificationmsg = [NSString stringWithFormat:@"Rewatching %@ Episode %@",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]];
                }
                else {
                    notificationmsg = [NSString stringWithFormat:@"%@ Episode %@",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]];
                }
                [self showNotification:@"Scrobble Successful." message:notificationmsg];
                // Sync with MAL if Enabled
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MALSyncEnabled"]) {
                    BOOL malsyncsuccess = [haengine sync];
                    if (!malsyncsuccess) {
                        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:@"MyAnimeList Sync failed, see console log."];
                    }
                }
                //Add History Record
                [HistoryWindow addrecord:[haengine getLastScrobbledActualTitle] Episode:[haengine getLastScrobbledEpisode] Date:[NSDate date]];
                break;
            }
            case 23:
                [self setStatusText:@"Scrobble Status: Scrobble Queued..."];
                [self showNotification:@"Scrobble Queued." message:[NSString stringWithFormat:@"%@ - %@",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
                break;
            case 51:
                if ([(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"] boolValue]) {
                    [self showCorrectionSearchWindow:self];
                }
                else {
                    [self setStatusText:NSLocalizedString(@"Scrobble Status: Can't find title. Retrying in 5 mins...",nil)];
                    [self showNotification:NSLocalizedString(@"Couldn't find title.",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Click here to find %@ manually.",nil), [haengine getFailedTitle]]];
                } 
                break;
            case 52:
            case 53:
                [self showNotification:NSLocalizedString(@"Scrobble Unsuccessful.",nil) message:NSLocalizedString(@"Retrying in 5 mins...",nil)];
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobble Failed. Retrying in 5 mins...",nil)];
                break;
            case 54:
                [self showNotification:NSLocalizedString(@"Scrobble Unsuccessful.",nil) message:NSLocalizedString(@"Check user credentials in Preferences. You may need to login again.",nil)];
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobble Failed. User credentials might have expired.",nil)];
                break;
            case 55:
                [self setStatusText:NSLocalizedString(@"Scrobble Status: No internet connection.",nil)];
                break;
            default:
                break;
        }
    });
}
-(void)performRefreshUI:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([haengine getSuccess] == 1) {
            [findtitle setHidden:true];
            [self setStatusMenuTitleEpisode:[haengine getLastScrobbledActualTitle] episode:[haengine getLastScrobbledEpisode]];
            if (status != 3 && [haengine getConfirmed]) {
                // Show normal info
                [self updateLastScrobbledTitleStatus:false];
                //Enable Update Status functions
                [self EnableStatusUpdating:YES];
                [confirmupdate setHidden:YES];
                [self showRevertRewatchMenu];
            }
            else {
                // Show that user needs to confirm update
                [self updateLastScrobbledTitleStatus:true];
                [confirmupdate setHidden:NO];
                if ([haengine getisNewTitle]) {
                    // Disable Update Status functions for new and unconfirmed titles.
                    [self EnableStatusUpdating:NO];
                    [revertrewatch setHidden:YES];
                }
                else {
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
    
}

#pragma mark Timer Functions

- (IBAction)toggletimer:(id)sender {
	//Check to see if a token exist
	if (![haengine getFirstAccount]) {
        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Please log in with your account in Preferences before you enable scrobbling",nil)];
    }
	else {
		if (scrobbling == FALSE) {
			[self starttimer];
			[togglescrobbler setTitle:NSLocalizedString(@"Stop Scrobbling",nil)];
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Auto Scrobble is now turned on.",nil)];
			ScrobblerStatus.objectValue = @"Scrobble Status: Started";
			//Set Scrobbling State to true
			scrobbling = TRUE;
		}
		else {
			[self stoptimer];
			[togglescrobbler setTitle:NSLocalizedString(@"Start Scrobbling",nil)];
			ScrobblerStatus.objectValue = @"Scrobble Status: Stopped";
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Auto Scrobble is now turned off.",nil)];
			//Set Scrobbling State to false
			scrobbling = FALSE;
		}
	}
	
}
-(void)autostarttimer {
	//Check to see if there is an API Key stored
	if (![haengine getFirstAccount]) {
         [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Unable to start scrobbling since there is no login. Please verify your login in Preferences.",nil)];
	}
	else {
		[self starttimer];
		[togglescrobbler setTitle:NSLocalizedString(@"Stop Scrobbling",nil)];
		ScrobblerStatus.objectValue = @"Scrobble Status: Started";
		//Set Scrobbling State to true
		scrobbling = TRUE;
	}
}
-(void)firetimer {
	//Tell haengine to detect and scrobble if necessary.
	NSLog(@"Starting...");
    if (!scrobbleractive) {
        scrobbleractive = true;
        // Disable toggle scrobbler and update now menu items
        [self toggleScrobblingUIEnable:false];
        
        if ([haengine checkexpired]) {
            [haengine refreshtoken];
            scrobbleractive = false;
            return;
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
            // Check for latest list of Auto Exceptions automatically each week
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"]) {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] timeIntervalSinceNow] < -604800) {
                    // Has been 1 Week, update Auto Exceptions
                    [AutoExceptions updateAutoExceptions];
                }
            }
			else {
				// First time, populate
				[AutoExceptions updateAutoExceptions];
			}
        }
        int status = 0;
        for (int i = 0; i < 2; i++) {
            if (i == 0) {
                if ([haengine getQueueCount] > 0 && [haengine getOnlineStatus]) {
                    NSDictionary * status = [haengine scrobblefromqueue];
                    int success = [status[@"success"] intValue];
                    int fail = [status[@"fail"] intValue];
                    bool confirmneeded = [status[@"confirmneeded"] boolValue];
                    if (confirmneeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self setStatusText:@"Scrobble Status: Please confirm update."];
                            NSDictionary * userinfo = @{@"title": [haengine getLastScrobbledTitle],  @"episode": [haengine getLastScrobbledEpisode]};
                            [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]] updateData:userinfo];
                        });
                        break;
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showNotification:@"Updated Queued Items" message:[NSString stringWithFormat:@"%i scrobbled successfully and %i failed",success, fail]];
                        });
                    }
                    

                }
            }
            else {
                status = [haengine startscrobbling];
                [self performsendupdatenotification:status];
            }
        }
        [self performRefreshUI:status];
    }
}
-(void)starttimer {
	NSLog(@"Auto Scrobble Started.");
    timer = [MSWeakTimer scheduledTimerWithTimeInterval:[[(NSNumber *)[NSUserDefaults standardUserDefaults] valueForKey:@"timerinterval"] intValue]
                                                 target:self
                                               selector:@selector(firetimer)
                                               userInfo:nil
                                                repeats:YES
                                          dispatchQueue:_privateQueue];
}
-(void)stoptimer {
	NSLog(@"Auto Scrobble Stopped.");
	//Stop Timer
	[timer invalidate];
}

-(IBAction)updatenow:(id)sender{
    if ([haengine getFirstAccount]) {
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            [self firetimer];
        });
    }
    else
        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Please log in with your account in Preferences before using this program",nil)];
}

#pragma mark Correction
-(IBAction)showCorrectionSearchWindow:(id)sender{
    bool isVisible = window.visible;
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    // Check if Confirm is on for new title. If so, then disable ability to delete title.
    if ((!confirmupdate.hidden && [haengine getisNewTitle]) || !findtitle.hidden) {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:NO];
    }
    else {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:YES];
    }
    if (!findtitle.hidden) {
        //Use failed title
         [fsdialog setSearchField:[haengine getFailedTitle]];
    }
    else {
        //Get last scrobbled title
        [fsdialog setSearchField:[haengine getLastScrobbledTitle]];
    }
    if (isVisible) {
        [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
        [NSApp beginSheet:fsdialog.window
           modalForWindow:window modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    else {
        [NSApp beginSheet:fsdialog.window
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
            else {
                BOOL correctonce = [fsdialog getcorrectonce];
				if (!findtitle.hidden) {
					 [self addtoExceptions:[haengine getFailedTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[fsdialog getSelectedTotalEpisodes]];
				}
                else if ([haengine getLastScrobbledEpisode].intValue == [fsdialog getSelectedTotalEpisodes]) {
                    // Detected episode equals the total episodes, do not add a rule and only do a correction just once.
                    correctonce = true;
                }
				else if (!correctonce) {
                    // Add to Exceptions
					 [self addtoExceptions:[haengine getLastScrobbledTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[fsdialog getSelectedTotalEpisodes]];
				}
                if([fsdialog getdeleteTitleonCorrection]) {
                    if([haengine removetitle:[haengine getAniID]]) {
                        NSLog(@"Removal Successful");
                    }
                }
                NSLog(@"Updating corrected title...");
                int status;
				if (!findtitle.hidden) {
					status = [haengine scrobbleagain:[haengine getFailedTitle] Episode:[haengine getFailedEpisode] correctonce:false];
				}
                else if (correctonce) {
                    status = [haengine scrobbleagain:[fsdialog getSelectedTitle] Episode:[haengine getLastScrobbledEpisode] correctonce:true];
                }
				else {
                    status = [haengine scrobbleagain:[haengine getLastScrobbledTitle] Episode:[haengine getLastScrobbledEpisode] correctonce:false];
				}
					
                switch (status) {
                    case 1:
                    case 2:
                    case 21:
                    case 22:{
                        [self setStatusText:NSLocalizedString(@"Scrobble Status: Correction Successful...",nil)];
                        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Correction was successful",nil)];
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
                        // Sync with MAL if Enabled
                        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MALSyncEnabled"]) {
                            BOOL malsyncsuccess = [haengine sync];
                            if (!malsyncsuccess) {
                                [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"MyAnimeList Sync failed, see console log.",nil)];
                            }
                        }
                        break;
                    }
                    default:
                        [self setStatusText:NSLocalizedString(@"Scrobble Status: Correction unsuccessful...",nil)];
                        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Correction was not successful.",nil)];
                        break;
                }
            }
        }
        else {
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
    allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
    NSError * error = nil;
    NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
    BOOL exists = false;
    for (NSManagedObject * entry in exceptions) {
        int offset = ((NSNumber *)[entry valueForKey:@"episodeOffset"]).intValue;
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
    [historywindowcontroller.window makeKeyAndOrderFront:nil];

}
#pragma mark StatusIconTooltip, Status Text, Last Scrobbled Title Setters


-(void)setStatusToolTip:(NSString*)toolTip
{
    statusItem.toolTip = toolTip;
}
-(void)setStatusText:(NSString*)messagetext
{
	ScrobblerStatus.objectValue = messagetext;
}
-(void)setLastScrobbledTitle:(NSString*)messagetext
{
	LastScrobbled.objectValue = messagetext;
}
-(void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode{
    //Set New Title and Episode
    updatedtitle.title = title;
    updatedepisode.title = [NSString stringWithFormat:NSLocalizedString(@"Episode %@",nil), episode];
}
-(void)updateLastScrobbledTitleStatus:(BOOL)pending{
    if (pending) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:NSLocalizedString(@"Pending:",nil)];
        [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Pending: %@ - Episode %@ playing from %@",nil),[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@ (Pending)",nil),[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
    }
    else if (![haengine getOnlineStatus]) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:NSLocalizedString(@"Queued:",nil)];
        [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Queued: %@ - Episode %@ playing from %@",nil),[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@ (Queued)",nil),[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
    }
    else {
        [updatecorrect setAutoenablesItems:YES];
        if ([haengine getRewatching]) {
            [lastupdateheader setTitle:NSLocalizedString(@"Rewatching:",nil)];
            [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Rewatching: %@ - Episode %@ playing from %@",nil),[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
        }
        else {
            [lastupdateheader setTitle:NSLocalizedString(@"Last Scrobbled:",nil)];
            [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Last Scrobbled: %@ - Episode %@ playing from %@",nil),[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
        }
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@",nil),[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
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
    [self showUpdateDialog:self.window];
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
    showtitle.objectValue = [haengine getLastScrobbledActualTitle];
    showscore.stringValue = [NSString stringWithFormat:@"%f", [haengine getScore]];
    episodefield.stringValue = [NSString stringWithFormat:@"%i", [haengine getCurrentEpisode]];
    if ([haengine getTotalEpisodes]  !=0) {
        epiformatter.maximum = @([haengine getTotalEpisodes]);
    }
    [showstatus selectItemAtIndex:[haengine getWatchStatus]];
    notes.string = [haengine getNotes];
    isPrivate.state = [haengine getPrivate];
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
}
- (void)updateDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
    if (returnCode == 1) {
        // Check if Episode field is empty. If so, set it to last scrobbled episode
        NSString * tmpepisode = episodefield.stringValue;
        bool episodechanged = false;
        if (tmpepisode.length == 0) {
            tmpepisode = [NSString stringWithFormat:@"%i", [haengine getCurrentEpisode]];
        }
        if (tmpepisode.intValue != [haengine getCurrentEpisode]) {
            episodechanged = true; // Used to update the status window
        }
        BOOL result = [haengine updatestatus:[haengine getAniID] episode:tmpepisode score:showscore.floatValue watchstatus:showstatus.titleOfSelectedItem notes:notes.textStorage.string isPrivate:(BOOL) isPrivate.state];
        if (result) {
            dispatch_async(dispatch_get_main_queue(), ^{
            [self setStatusText:NSLocalizedString(@"Scrobble Status: Updating of Watch Status/Score Successful.",nil)];
            if (episodechanged) {
                // Update the tooltip, menu and last scrobbled title
                [self setStatusMenuTitleEpisode:[haengine getLastScrobbledActualTitle] episode:[haengine getLastScrobbledEpisode]];
                [self updateLastScrobbledTitleStatus:false];
            }
            });
            // Sync MyAnimeList
            [self syncMyAnimeList];
        }
        else {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self setStatusText:NSLocalizedString(@"Scrobble Status: Unable to update Watch Status/Score.",nil)];
          });
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
    //If scrobbling is on, restart timer
	if (scrobbling == TRUE) {
		[self starttimer];
	}
        [self enableUpdateItems]; //Reenable update items
    });
    });
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
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Do you want to stop rewatching %@?",nil),[haengine getLastScrobbledTitle]];
    [alert setInformativeText:NSLocalizedString(@"This will revert the title status back to it's completed state.",nil)];
    // Set Message type to Informational
    alert.alertStyle = NSInformationalAlertStyle;
    if ([alert runModal]== NSAlertFirstButtonReturn) {
        // Revert title
        BOOL success = [haengine stopRewatching:[haengine getAniID]];
        if (success) {
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@'s rewatch status has been reverted.",nil), [haengine getLastScrobbledTitle]]];
            // Show Correct State in the UI
            [self showRevertRewatchMenu];
            [self updateLastScrobbledTitleStatus:false];
            // Sync with MAL if Enabled
            [self syncMyAnimeList];
        }
        else {
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Rewatch revert was unsuccessful.",nil)];
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
        if ([[haengine getLastScrobbledTitle] isEqualToString:title] && episode.intValue == [haengine getLastScrobbledEpisode].intValue) {
            //Confirm Update
            [self confirmupdate];
        }
        else {
            return;
        }
    }
    else if ([notification.title isEqualToString:@"Couldn't find title."] && !findtitle.hidden) {
        //Find title
        [self showCorrectionSearchWindow:nil];
    }
}
-(IBAction)confirmupdate:(id)sender{
    [self confirmupdate];
}
-(void)confirmupdate{
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{

    BOOL success = [haengine confirmupdate];
    if (success) {
         dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLastScrobbledTitleStatus:false];
            [HistoryWindow addrecord:[haengine getLastScrobbledActualTitle] Episode:[haengine getLastScrobbledEpisode] Date:[NSDate date]];
            [confirmupdate setHidden:YES];
            [self setStatusText:@"Scrobble Status: Update was successful."];
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
            if ([haengine getisNewTitle]) {
                // Enable Update Status functions for new and unconfirmed titles.
                [self EnableStatusUpdating:YES];
            }
             [self showRevertRewatchMenu];
         });
        // Sync with MAL if Enabled
        [self syncMyAnimeList];
    }
    else {
         dispatch_async(dispatch_get_main_queue(), ^{
        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:@"Failed to confirm update. Please try again later."];
        [self setStatusText:@"Unable to confirm update."];
         });
    }
            });
}
#pragma mark Hotkeys
-(void)registerHotkey{
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceScrobbleNowShortcut toAction:^{
         // Scrobble Now Global Hotkey
         dispatch_queue_t queue = dispatch_get_global_queue(
                                                            DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
         
         dispatch_async(queue, ^{
             if ([haengine getFirstAccount] && !panelactive) {
                 [self firetimer];
             }
         });
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceShowStatusMenuShortcut toAction:^{
         // Status Window Toggle Global Hotkey
         [self togglescrobblewindow:nil];
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceToggleScrobblingShortcut toAction:^{
         // Auto Scrobble Toggle Global Hotkey
         [self toggletimer:nil];
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceConfirmUpdateShortcut toAction:^{
         // Confirm Update Hotkey
         if (!confirmupdate.hidden) {
             [self confirmupdate];
         }
     }];
}

#pragma mark Misc
-(void)showAnimeInfo:(NSDictionary *)d{
    //Empty
    animeinfo.string = @"";
    //Title
    NSDictionary * titles = d[@"titles"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"%@", titles[@"en_jp"]]];
    if (titles[@"en"] != [NSNull null] && [NSString stringWithFormat:@"%@", titles[@"en"]].length >0) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Also known as %@", titles[@"en"]]];
    }
    [self appendToAnimeInfo:@""];
    //Description
    [self appendToAnimeInfo:@"Description"];
    [self appendToAnimeInfo:d[@"synopsis"]];
    //Meta Information
    [self appendToAnimeInfo:@""];
    [self appendToAnimeInfo:@"Other Information"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Start Date: %@", d[@"startDate"]]];
    if (d[@"endDate"] != [NSNull null]) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Finished Airing: %@", d[@"endDate"]]];
    }
    if (d[@"episode_count"]) {
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %@", d[@"episodeCount"]]];
    }
    else {
        [self appendToAnimeInfo:@"Episodes: Unknown"];
    }
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Show Type: %@", d[@"showType"]]];
    if (d[@"age_rating"] != [NSNull null]) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Age Rating: %@", d[@"ageRating"]]];
    }
    //Image
    NSDictionary * posterimg = d[@"posterImage"];
    NSImage * dimg = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", posterimg[@"original"]]]]; //Downloads Image
    img.image = dimg; //Get the Image for the title
    // Clear Anime Info so that Hachidori won't attempt to retrieve it if the same episode and title is playing
    [haengine clearAnimeInfo];
}

- (void)appendToAnimeInfo:(NSString*)text
{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
        [animeinfo.textStorage appendAttributedString:attr];
}
-(void)showRevertRewatchMenu{
    if ([haengine getRewatching]) {
        [revertrewatch setHidden:NO];
    }
    else {
        [revertrewatch setHidden:YES];
    }
}
-(NSDictionary *)getNowPlaying{
	// Outputs Currently Playing information into JSON
	NSMutableDictionary * output = [NSMutableDictionary new];
	if ((haengine.getLastScrobbledTitle).length > 0) {
		output[@"id"] = [haengine getAniID];
		output[@"scrobbledtitle"] = [haengine getLastScrobbledTitle];
		output[@"scrobbledactualtitle"] = [haengine getLastScrobbledActualTitle];
		output[@"scrobbledEpisode"] = [haengine getLastScrobbledEpisode];
		output[@"source"] = [haengine getLastScrobbledSource];
	}
	return output;
}
-(Hachidori *)getHachidoriInstance{
    return haengine;
}
#pragma mark Share Services
-(void)generateShareMenu{
    //Clear Share Menu
    [shareMenu removeAllItems];
    // Workaround for Share Toolbar Item
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    shareIcon.image = [NSImage imageNamed:NSImageNameShareTemplate];
    [shareIcon setHidden:YES];
    shareIcon.title = @"";
    [shareMenu addItem:shareIcon];
    //Generate Items to Share
    shareItems = @[[NSString stringWithFormat:@"%@ - %@", [haengine getLastScrobbledActualTitle], [haengine getLastScrobbledEpisode] ], [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", [haengine getAniID]]]];
    //Get Share Services for Items
    NSArray *shareServiceforItems = [NSSharingService sharingServicesForItems:shareItems];
    //Generate Share Items and populate Share Menu
    for (NSSharingService * cservice in shareServiceforItems) {
        NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:cservice.title action:@selector(shareFromService:) keyEquivalent:@""];
        item.representedObject = cservice;
        item.image = cservice.image;
        item.target = self;
        [shareMenu addItem:item];
    }
}
- (IBAction)shareFromService:(id)sender{
    // Share Item
    [[sender representedObject] performWithItems:shareItems];
}
-(IBAction)showLastScrobbledInformation:(id)sender{
    //Open the anime's page on Kitsu in the default web browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", [haengine getAniID]]]];
}
#pragma mark MyAnimeList Syncing
-(IBAction)forceMALSync:(id)sender{
    [ForceMALSync setEnabled:NO];
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        BOOL malsyncsuccess = [haengine sync];
         dispatch_async(dispatch_get_main_queue(), ^{
             if (!malsyncsuccess) {
                 [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"MyAnimeList Sync failed, see console log.",nil)];
             }
             [ForceMALSync setEnabled:YES];
             // Show Donation Message
             [Utility donateCheck:self];
            });
        });
}
-(void)syncMyAnimeList{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MALSyncEnabled"]) {
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            BOOL malsyncsuccess = [haengine sync];
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (!malsyncsuccess) {
                     [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"MyAnimeList Sync failed, see console log.",nil)];
                 }
                 // Show Donation Message
                 [Utility donateCheck:self];
             });
        });
    }
}
#pragma mark Streamlink
- (IBAction)openstream:(id)sender {
    if ([haengine getFirstAccount]) {
        streamlinkdetector * detector = [streamlinkdetector new];
        if ([detector checkifStreamLinkExists]) {
            // Shows the Open Stream dialog
            [NSApp activateIgnoringOtherApps:YES];
            if ([haengine getOnlineStatus]) {
                if (!streamlinkopenw)
                    streamlinkopenw = [streamlinkopen new];
                
                bool isVisible = window.visible;
                if (isVisible) {
                    [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
                    [NSApp beginSheet:streamlinkopenw.window
                       modalForWindow:window modalDelegate:self
                       didEndSelector:@selector(streamopenDidEnd:returnCode:contextInfo:)
                          contextInfo:(void *)nil];
                }
                else {
                    [NSApp beginSheet:streamlinkopenw.window
                       modalForWindow:nil modalDelegate:self
                       didEndSelector:@selector(streamopenDidEnd:returnCode:contextInfo:)
                          contextInfo:(void *)nil];
                }
            }
            else {
                [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"You need to be online to use this feature.",nil)];
            }
        }
        else {
            [detector checkStreamLink:nil];
        }
    }
    else {
        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Add a login before you use this feature.",nil)];
    }
}
-(void)streamopenDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 0) {
        streamlinkopenw = nil;
    }
    else {
        [self toggleScrobblingUIEnable:false];
        NSString * streamurl = streamlinkopenw.streamurl.stringValue;
        NSString * stream = streamlinkopenw.streams.title;
        dispatch_queue_t queue = dispatch_get_global_queue(
                                                           DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            int status = [haengine scrobblefromstreamlink:streamurl withStream:stream];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performsendupdatenotification:status];
                [self performRefreshUI:status];
                streamlinkopenw = nil;
            });
        });
    }
}

@end
