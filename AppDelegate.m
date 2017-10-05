//
//  AppDelegate.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
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
#import <MSWeakTimer_macOS/MSWeakTimer.h>
#import "ClientConstants.h"
#import "StatusUpdateWindow.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "ShareMenu.h"
#import "PFAboutWindowController.h"

@implementation AppDelegate

@synthesize window;
@synthesize historywindowcontroller;
@synthesize fsdialog;
@synthesize managedObjectContext;
@synthesize statusMenu;
@synthesize statusItem;
@synthesize statusImage;
@synthesize timer;
@synthesize openstream;
@synthesize togglescrobbler;
@synthesize updatenow;
@synthesize confirmupdate;
@synthesize findtitle;
@synthesize seperator;
@synthesize lastupdateheader;
@synthesize updatecorrectmenu;
@synthesize updatecorrect;
@synthesize updatedtitle;
@synthesize updatedepisode;
@synthesize seperator2;
@synthesize updatedcorrecttitle;
@synthesize updatedupdatestatus;
@synthesize revertrewatch;
@synthesize shareMenuItem;
@synthesize ForceMALSync;
@synthesize ScrobblerStatus;
@synthesize LastScrobbled;
@synthesize openAnimePage;
@synthesize animeinfo;
@synthesize img;
@synthesize windowcontent;
@synthesize animeinfooutside;
@synthesize scrobbling;
@synthesize scrobbleractive;
@synthesize panelactive;
@synthesize haengine;
@synthesize updatetoolbaritem;
@synthesize correcttoolbaritem;
@synthesize sharetoolbaritem;
@synthesize _preferencesWindowController;
@synthesize streamlinkopenw;


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
    defaultValues[@"enableplexapi"] = @NO;
    defaultValues[@"plexaddress"] = @"localhost";
    defaultValues[@"plexport"] = @"32400";
    defaultValues[@"plexidentifier"] = @"Hachidori_Plex_Client";
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
	haengine.managedObjectContext = managedObjectContext;
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
        NSViewController *plexviewController = [PlexPrefs new];
        NSViewController *advancedViewController = [[AdvancedPrefController alloc] initwithAppDelegate:self];
        NSArray *controllers = @[generalViewController, loginViewController, hotkeyViewController , plexviewController, exceptionsViewController, suViewController, advancedViewController];
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers];
    }
    return _preferencesWindowController;
}

- (IBAction)showPreferences:(id)sender
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
- (IBAction)togglescrobblewindow:(id)sender
{
	if (window.visible) {
        [window close];
	} else { 
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:self]; 
	} 
}
- (IBAction)showOfflineQueue:(id)sender{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_owindow) {
        _owindow = [[OfflineViewQueue alloc] init];
    }
    [_owindow.window makeKeyAndOrderFront:nil];
}
- (IBAction)getHelp:(id)sender{
    //Show Help
 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Getting-Started"]];
}
- (IBAction)showAboutWindow:(id)sender{
    // Properly show the about window in a menu item application
    [NSApp activateIgnoringOtherApps:YES];
    if (!_aboutWindowController) {
        _aboutWindowController = [PFAboutWindowController new];
    }
    (self.aboutWindowController).appURL = [[NSURL alloc] initWithString:@"https://hachidori.ateliershiori.moe/"];
    NSMutableString *copyrightstr = [NSMutableString new];
    NSDictionary *bundleDict = [NSBundle mainBundle].infoDictionary;
    [copyrightstr appendFormat:@"%@ \r\r",bundleDict[@"NSHumanReadableCopyright"]];
    if (((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]).boolValue) {
        [copyrightstr appendFormat:@"This copy is registered to: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
    }
    else {
        [copyrightstr appendString:@"UNREGISTERED COPY"];
    }
    (self.aboutWindowController).appCopyright = [[NSAttributedString alloc] initWithString:copyrightstr
                                                                                attributes:@{
                                                                                             NSForegroundColorAttributeName:[NSColor labelColor],
                                                                                             NSFontAttributeName:[NSFont fontWithName:[NSFont systemFontOfSize:12.0f].familyName size:11]}];
    
    [self.aboutWindowController showWindow:nil];
}
- (void)disableUpdateItems{
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
- (void)enableUpdateItems{
    // Reenables update options
    panelactive = false;
    [updatenow setEnabled:YES];
    [togglescrobbler setEnabled:YES];
    [updatedcorrecttitle setEnabled:YES];
    if (confirmupdate.hidden) {
        [updatedupdatestatus setEnabled:YES];
    }
    if (!confirmupdate.hidden && !haengine.LastScrobbledTitleNew) {
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
- (void)unhideMenus{
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
- (void)toggleScrobblingUIEnable:(BOOL)enable{
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
- (void)EnableStatusUpdating:(BOOL)enable{
    ForceMALSync.enabled = enable;
	updatecorrect.autoenablesItems = enable;
    updatetoolbaritem.enabled = enable;
    updatedupdatestatus.enabled = enable;
    revertrewatch.enabled = enable;
}
- (void)enterDonationKey{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_dwindow) {
        _dwindow = [[DonationWindowController alloc] init];
    }
    [_dwindow.window makeKeyAndOrderFront:nil];
    
}
- (IBAction)enterDonationKey:(id)sender {
    [self enterDonationKey];
}
- (void)performsendupdatenotification:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Enable the Update button if a title is detected
        switch (status) { // 0 - nothing playing; 1 - same episode playing; 21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed;
            case ScrobblerNothingPlaying:
                [self setStatusText:@"Scrobble Status: Idle..."];
                break;
            case ScrobblerSameEpisodePlaying:
                [self setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
                break;
            case ScrobblerUpdateNotNeeded:
                [self setStatusText:@"Scrobble Status: No update needed."];
                break;
            case ScrobblerConfirmNeeded:{
                [self setStatusText:@"Scrobble Status: Please confirm update."];
                NSDictionary * userinfo = @{@"title": haengine.LastScrobbledTitle,  @"episode": haengine.LastScrobbledEpisode};
                [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode] updateData:userinfo];
                break;
            }
            case ScrobblerAddTitleSuccessful:
            case ScrobblerUpdateSuccessful:{
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                NSString * notificationmsg;
                if (haengine.rewatching) {
                    notificationmsg = [NSString stringWithFormat:@"Rewatching %@ Episode %@",haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode];
                }
                else {
                    notificationmsg = [NSString stringWithFormat:@"%@ Episode %@",haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode];
                }
                [self showNotification:@"Scrobble Successful." message:notificationmsg];
                [self syncMyAnimeList];
                //Add History Record
                [HistoryWindow addrecord:haengine.LastScrobbledActualTitle Episode:haengine.LastScrobbledEpisode Date:[NSDate date]];
                break;
            }
            case ScrobblerOfflineQueued:
                [self setStatusText:@"Scrobble Status: Scrobble Queued..."];
                [self showNotification:@"Scrobble Queued." message:[NSString stringWithFormat:@"%@ - %@",haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode]];
                break;
            case ScrobblerTitleNotFound:
                if (!((NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"]).boolValue) {
                    [self setStatusText:NSLocalizedString(@"Scrobble Status: Can't find title. Retrying in 5 mins...",nil)];
                    [self showNotification:NSLocalizedString(@"Couldn't find title.",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Click here to find %@ manually.",nil), haengine.FailedTitle]];
                } 
                break;
            case ScrobblerAddTitleFailed:
            case ScrobblerUpdateFailed:
                [self showNotification:NSLocalizedString(@"Scrobble Unsuccessful.",nil) message:NSLocalizedString(@"Retrying in 5 mins...",nil)];
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobble Failed. Retrying in 5 mins...",nil)];
                break;
            case ScrobblerFailed:
                [self showNotification:NSLocalizedString(@"Scrobble Unsuccessful.",nil) message:NSLocalizedString(@"Check user credentials in Preferences. You may need to login again.",nil)];
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobble Failed. User credentials might have expired.",nil)];
                break;
            default:
                break;
        }
    });
}
- (void)performRefreshUI:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (haengine.Success == 1) {
            [findtitle setHidden:true];
            [self setStatusMenuTitleEpisode:haengine.LastScrobbledActualTitle episode:haengine.LastScrobbledEpisode];
            if (status != 3 && haengine.confirmed) {
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
                if (haengine.LastScrobbledTitleNew) {
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
            NSDictionary * ainfo = haengine.LastScrobbledInfo;
            if (ainfo !=nil) { // Checks if Hachidori already populated info about the just updated title.
                [self showAnimeInfo:ainfo];
                [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", haengine.LastScrobbledActualTitle, haengine.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", haengine.AniID]]]];
            }
        }
        if (status == ScrobblerTitleNotFound) {
            //Show option to find title
            [findtitle setHidden:false];
            if (((NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"]).boolValue) {
                [self showCorrectionSearchWindow:self];
            }
        }
        // Enable Menu Items
        scrobbleractive = false;
        [self toggleScrobblingUIEnable:true];
    });
    
}

- (void)resetUI {
    // Resets the UI when the user logs out
    [_shareMenu resetShareMenu];
    [updatecorrect setAutoenablesItems:NO];
    [self EnableStatusUpdating:NO];
    [revertrewatch setHidden:YES];
    [sharetoolbaritem setEnabled:NO];
    [correcttoolbaritem setEnabled:NO];
    [openAnimePage setEnabled:NO];
    [findtitle setHidden:YES];
    [confirmupdate setHidden:YES];
    lastupdateheader.hidden = YES;
    updatedtitle.hidden = YES;
    updatedepisode.hidden = YES;
    seperator2.hidden = YES;
    updatecorrectmenu.hidden = YES;
    shareMenuItem.hidden = YES;
    [haengine resetinfo];
    _nowplayingview.hidden = YES;
    _nothingplayingview.hidden = NO;
    [self setStatusToolTip:@"Hachidori"];
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
- (void)autostarttimer {
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
- (void)firetimer {
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
                if ([haengine getQueueCount] > 0 && haengine.online) {
                    NSDictionary * status = [haengine scrobblefromqueue];
                    int success = [status[@"success"] intValue];
                    int fail = [status[@"fail"] intValue];
                    bool confirmneeded = [status[@"confirmneeded"] boolValue];
                    if (confirmneeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self setStatusText:@"Scrobble Status: Please confirm update."];
                            NSDictionary * userinfo = @{@"title": haengine.LastScrobbledTitle,  @"episode": haengine.LastScrobbledEpisode};
                            [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode] updateData:userinfo];
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
- (void)starttimer {
	NSLog(@"Auto Scrobble Started.");
    timer = [MSWeakTimer scheduledTimerWithTimeInterval:[[(NSNumber *)[NSUserDefaults standardUserDefaults] valueForKey:@"timerinterval"] intValue]
                                                 target:self
                                               selector:@selector(firetimer)
                                               userInfo:nil
                                                repeats:YES
                                          dispatchQueue:_privateQueue];
}
- (void)stoptimer {
	NSLog(@"Auto Scrobble Stopped.");
	//Stop Timer
	[timer invalidate];
}

- (IBAction)updatenow:(id)sender{
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
- (IBAction)showCorrectionSearchWindow:(id)sender{
    bool isVisible = window.visible;
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    // Check if Confirm is on for new title. If so, then disable ability to delete title.
    if ((!confirmupdate.hidden && haengine.LastScrobbledTitleNew) || !findtitle.hidden) {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:NO];
    }
    else {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:YES];
    }
    if (!findtitle.hidden) {
        //Use failed title
         fsdialog.searchquery = haengine.FailedTitle;
    }
    else {
        //Get last scrobbled title
        fsdialog.searchquery = haengine.LastScrobbledTitle;
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
- (void)correctionDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
            if ([fsdialog.selectedaniid isEqualToString:haengine.AniID]) {
                NSLog(@"ID matches, correction not needed.");
            }
            else {
                BOOL correctonce = [fsdialog getcorrectonce];
				if (!findtitle.hidden) {
					 [self addtoExceptions:haengine.FailedTitle newtitle:fsdialog.selectedtitle showid:fsdialog.selectedaniid threshold:fsdialog.selectedtotalepisodes];
				}
                else if (haengine.LastScrobbledEpisode.intValue == fsdialog.selectedtotalepisodes) {
                    // Detected episode equals the total episodes, do not add a rule and only do a correction just once.
                    correctonce = true;
                }
				else if (!correctonce) {
                    // Add to Exceptions
					 [self addtoExceptions:haengine.LastScrobbledTitle newtitle:fsdialog.selectedtitle showid:fsdialog.selectedaniid threshold:fsdialog.selectedtotalepisodes];
				}
                if([fsdialog getdeleteTitleonCorrection]) {
                    if([haengine removetitle:haengine.AniID]) {
                        NSLog(@"Removal Successful");
                    }
                }
                NSLog(@"Updating corrected title...");
                int status;
				if (!findtitle.hidden) {
					status = [haengine scrobbleagain:haengine.FailedTitle Episode:haengine.FailedEpisode correctonce:false];
				}
                else if (correctonce) {
                    status = [haengine scrobbleagain:fsdialog.selectedtitle Episode:haengine.LastScrobbledEpisode correctonce:true];
                }
				else {
                    status = [haengine scrobbleagain:haengine.LastScrobbledTitle Episode:haengine.LastScrobbledEpisode correctonce:false];
				}
					
                switch (status) {
                    case ScrobblerSameEpisodePlaying:
                    case ScrobblerUpdateNotNeeded:
                    case ScrobblerAddTitleSuccessful:
                    case ScrobblerUpdateSuccessful: {
                        [self setStatusText:NSLocalizedString(@"Scrobble Status: Correction Successful...",nil)];
                        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Correction was successful",nil)];
                        [self setStatusMenuTitleEpisode:haengine.LastScrobbledActualTitle episode:haengine.LastScrobbledEpisode];
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
                        NSDictionary * ainfo = haengine.LastScrobbledInfo;
                        [self showAnimeInfo:ainfo];
                        [findtitle setHidden:YES];
                        [confirmupdate setHidden:true];
						//Regenerate Share Items
                        [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", haengine.LastScrobbledActualTitle, haengine.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", haengine.AniID]]]];
                        // Sync with MAL if Enabled
                        [self syncMyAnimeList];
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
- (void)addtoExceptions:(NSString *)detectedtitle newtitle:(NSString *)title showid:(NSString *)showid threshold:(int)threshold{
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

- (IBAction)showhistory:(id)sender
{
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
    if (!historywindowcontroller) {
        historywindowcontroller = [[HistoryWindow alloc] init];
    }
    [historywindowcontroller.window makeKeyAndOrderFront:nil];

}
#pragma mark StatusIconTooltip, Status Text, Last Scrobbled Title Setters


- (void)setStatusToolTip:(NSString*)toolTip
{
    statusItem.toolTip = toolTip;
}
- (void)setStatusText:(NSString*)messagetext
{
	ScrobblerStatus.objectValue = messagetext;
}
- (void)setLastScrobbledTitle:(NSString*)messagetext
{
	LastScrobbled.objectValue = messagetext;
}
- (void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode{
    //Set New Title and Episode
    updatedtitle.title = title;
    updatedepisode.title = [NSString stringWithFormat:NSLocalizedString(@"Episode %@",nil), episode];
}
- (void)updateLastScrobbledTitleStatus:(BOOL)pending{
    if (pending) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:NSLocalizedString(@"Pending:",nil)];
        [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Pending: %@ - Episode %@ playing from %@",nil),haengine.LastScrobbledTitle,haengine.LastScrobbledEpisode, haengine.LastScrobbledSource]];
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@ (Pending)",nil),haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode]];
    }
    else if (!haengine.online) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:NSLocalizedString(@"Queued:",nil)];
        [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Queued: %@ - Episode %@ playing from %@",nil),haengine.LastScrobbledTitle,haengine.LastScrobbledEpisode, haengine.LastScrobbledSource]];
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@ (Queued)",nil),haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode]];
    }
    else {
        [updatecorrect setAutoenablesItems:YES];
        if (haengine.rewatching) {
            [lastupdateheader setTitle:NSLocalizedString(@"Rewatching:",nil)];
            [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Rewatching: %@ - Episode %@ playing from %@",nil),haengine.LastScrobbledTitle,haengine.LastScrobbledEpisode, haengine.LastScrobbledSource]];
        }
        else {
            [lastupdateheader setTitle:NSLocalizedString(@"Last Scrobbled:",nil)];
            [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Last Scrobbled: %@ - Episode %@ playing from %@",nil),haengine.LastScrobbledTitle,haengine.LastScrobbledEpisode, haengine.LastScrobbledSource]];
        }
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@",nil),haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode]];
    }
}

#pragma mark Update Status functions

- (IBAction)updatestatus:(id)sender {
    [self showUpdateDialog:self.window];
    [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
}
- (IBAction)updatestatusmenu:(id)sender{
    [self showUpdateDialog:nil];
}
- (void)showUpdateDialog:(NSWindow *) w{
    [NSApp activateIgnoringOtherApps:YES];
    if (!_updatewindow) {
        _updatewindow = [StatusUpdateWindow new];
        // Set completion handler
        __weak AppDelegate *weakself = self;
        _updatewindow.completion = ^void(int returnCode){
            [weakself updateDidEnd:returnCode];
        };
    }
    // Show Dialog
    [_updatewindow showUpdateDialog:w withHachidori:haengine];
}
- (void)updateDidEnd:(int)returnCode {
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
    if (returnCode == 1) {
        // Check if Episode field is empty. If so, set it to last scrobbled episode
        NSString * tmpepisode = _updatewindow.episodefield.stringValue;
        bool episodechanged = false;
        if (tmpepisode.length == 0) {
            tmpepisode = [NSString stringWithFormat:@"%i", haengine.DetectedCurrentEpisode];
        }
        if (tmpepisode.intValue != haengine.DetectedCurrentEpisode) {
            episodechanged = true; // Used to update the status window
        }
        BOOL result = [haengine updatestatus:haengine.AniID episode:tmpepisode score:(int)_updatewindow.showscore.selectedTag watchstatus:_updatewindow.showstatus.titleOfSelectedItem notes:_updatewindow.notes.textStorage.string isPrivate:(BOOL) _updatewindow.isPrivate.state];
        if (result) {
            dispatch_async(dispatch_get_main_queue(), ^{
            [self setStatusText:NSLocalizedString(@"Scrobble Status: Updating of Watch Status/Score Successful.",nil)];
            if (episodechanged) {
                // Update the tooltip, menu and last scrobbled title
                [self setStatusMenuTitleEpisode:haengine.LastScrobbledActualTitle episode:haengine.LastScrobbledEpisode];
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

- (IBAction)revertRewatch:(id)sender{
    //Show Prompt
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Do you want to stop rewatching %@?",nil),haengine.LastScrobbledTitle];
    [alert setInformativeText:NSLocalizedString(@"This will revert the title status back to it's completed state.",nil)];
    // Set Message type to Informational
    alert.alertStyle = NSInformationalAlertStyle;
    if ([alert runModal]== NSAlertFirstButtonReturn) {
        // Revert title
        BOOL success = [haengine stopRewatching:haengine.AniID];
        if (success) {
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@'s rewatch status has been reverted.",nil), haengine.LastScrobbledTitle]];
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

- (void)showNotification:(NSString *)title message:(NSString *) message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = nil;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (void)showConfirmationNotification:(NSString *)title message:(NSString *) message updateData:(NSDictionary *)d{
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
        if ([haengine.LastScrobbledTitle isEqualToString:title] && episode.intValue == haengine.LastScrobbledEpisode.intValue) {
            //Confirm Update
            [self performconfirmupdate];
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
- (IBAction)confirmupdate:(id)sender{
    [self performconfirmupdate];
}
- (void)performconfirmupdate{
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{

    BOOL success = [haengine confirmupdate];
    if (success) {
         dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLastScrobbledTitleStatus:false];
            [HistoryWindow addrecord:haengine.LastScrobbledActualTitle Episode:haengine.LastScrobbledEpisode Date:[NSDate date]];
            [confirmupdate setHidden:YES];
            [self setStatusText:@"Scrobble Status: Update was successful."];
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",haengine.LastScrobbledActualTitle,haengine.LastScrobbledEpisode]];
            if (haengine.LastScrobbledTitleNew) {
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
- (void)registerHotkey{
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
             [self performconfirmupdate];
         }
     }];
}

#pragma mark Misc
- (void)showAnimeInfo:(NSDictionary *)d{
    //Empty
    animeinfo.string = @"";
    //Title
    NSDictionary * titles = d[@"titles"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"%@", titles[@"en_jp"]]];
    if (titles[@"en"] && titles[@"en"] != [NSNull null] && [NSString stringWithFormat:@"%@", titles[@"en"]].length >0) {
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
    if (d[@"episodeCount"]) {
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
    NSImage * dimg = (posterimg[@"original"] != [NSNull null] || posterimg[@"original"]) ? [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:(NSString *)posterimg[@"original"]]] : [NSImage imageNamed:@"missing"]; //Downloads Image
    img.image = dimg; //Get the Image for the title
    // Clear Anime Info so that Hachidori won't attempt to retrieve it if the same episode and title is playing
    [haengine clearAnimeInfo];
    // Refresh view
    _nowplayingview.hidden = NO;
    _nothingplayingview.hidden = YES;
}

- (void)appendToAnimeInfo:(NSString*)text
{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
        [animeinfo.textStorage appendAttributedString:attr];
}
- (void)showRevertRewatchMenu{
    if (haengine.rewatching) {
        [revertrewatch setHidden:NO];
    }
    else {
        [revertrewatch setHidden:YES];
    }
}
- (NSDictionary *)getNowPlaying{
	// Outputs Currently Playing information into JSON
	NSMutableDictionary * output = [NSMutableDictionary new];
	if ((haengine.getLastScrobbledTitle).length > 0) {
		output[@"id"] = haengine.AniID;
		output[@"scrobbledtitle"] = haengine.LastScrobbledTitle;
		output[@"scrobbledactualtitle"] = haengine.LastScrobbledActualTitle;
		output[@"scrobbledEpisode"] = haengine.LastScrobbledEpisode;
		output[@"source"] = haengine.LastScrobbledSource;
	}
	return output;
}
- (IBAction)showLastScrobbledInformation:(id)sender{
    //Open the anime's page on Kitsu in the default web browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", haengine.AniID]]];
}
#pragma mark MyAnimeList Syncing
- (IBAction)forceMALSync:(id)sender{
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
- (void)syncMyAnimeList{
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

@end
