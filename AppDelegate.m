//
//  AppDelegate.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "AppDelegate.h"
#import "PFMoveApplication.h"
#import "Preferences.h"
#import "FixSearchDialog.h"
#import "Hotkeys.h"
#import "AutoExceptions.h"
#import "ExceptionsCache.h"
#import "Utility.h"

@implementation AppDelegate

@synthesize window;
@synthesize historywindow;
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
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
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
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
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
	[defaultValues setObject:@"" forKey:@"Token"];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ScrobbleatStartup"];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"setprivate"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"useSearchCache"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"exceptions"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"ignoredirectories"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"IgnoreTitleRules"];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ConfirmNewTitle"];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"ConfirmUpdates"];
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9){
            //Yosemite Specific Advanced Options
        	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"DisableYosemiteTitleBar"];
        	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"DisableYosemiteVibrance"];
    }
	//Register Dictionary
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults:defaultValues];
	
}
- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"hachidori-status" ofType:@"png"]];
    
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

	//Sort Date Column by default
	NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
										 initWithKey: @"Date" ascending: NO];
	[historytable setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Initialize haengine
    haengine = [[Hachidori alloc] init];
	[haengine setManagedObjectContext:managedObjectContext];
	// Insert code here to initialize your application
	//Check if Application is in the /Applications Folder
	PFMoveToApplicationsFolderIfNecessary();
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
        
    }
    // Fix template images
    // There is a bug where template images are not made even if they are set in XCAssets
    NSArray *images = [NSArray arrayWithObjects:@"update", @"history", @"correct", nil];
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
            [NSApp activateIgnoringOtherApps:YES];
            [self.preferencesWindowController showWindow:nil];
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
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, loginViewController, hotkeyViewController , exceptionsViewController, suViewController, nil];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers];
    }
    return _preferencesWindowController;
}

-(void)showPreferences:(id)sender
{
	//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
	[NSApp activateIgnoringOtherApps:YES];
	[self.preferencesWindowController showWindow:nil];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
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
        alert = nil;
        
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


#pragma mark Timer Functions

- (IBAction)toggletimer:(id)sender {
	//Check to see if a token exist
	if (![Utility checktoken]) {
        [self showNotication:@"Hachidori" message:@"Please log in with your account in Preferences before you enable scrobbling"];
    }
	else {
		if (scrobbling == FALSE) {
			[self starttimer];
			[togglescrobbler setTitle:@"Stop Scrobbling"];
            [self showNotication:@"Hachidori" message:@"Auto Scrobble is now turned on."];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
			//Set Scrobbling State to true
			scrobbling = TRUE;
		}
		else {
			[self stoptimer];
			[togglescrobbler setTitle:@"Start Scrobbling"];
			[ScrobblerStatus setObjectValue:@"Scrobble Status: Stopped"];
            [self showNotication:@"Hachidori" message:@"Auto Scrobble is now turned off."];
			//Set Scrobbling State to false
			scrobbling = FALSE;
		}
	}
	
}
-(void)autostarttimer {
	//Check to see if there is an API Key stored
	if (![Utility checktoken]) {
         [self showNotication:@"Hachidori" message:@"Unable to start scrobbling since there is no login. Please verify your login in Preferences."];
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
        [statusMenu setAutoenablesItems:NO];
        [updatenow setEnabled:NO];
        [togglescrobbler setEnabled:NO];
        [confirmupdate setEnabled:NO];
		[findtitle setEnabled:NO];
        [updatenow setTitle:@"Updating..."];
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
            // Check for latest list of Auto Exceptions automatically each week
            if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] isEqualTo:nil]) {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] timeIntervalSinceNow] < -604800) {
                    // Has been 1 Week, update Auto Exceptions
                    [AutoExceptions updateAutoExceptions];
                }
            }
        }
        [self setStatusText:@"Scrobble Status: Scrobbling..."];
        int status;
        status = [haengine startscrobbling];
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
                NSDictionary * userinfo = [[NSDictionary alloc] initWithObjectsAndKeys:[haengine getLastScrobbledTitle], @"title",  [haengine getLastScrobbledEpisode], @"episode", nil];
                [self showConfirmationNotication:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]] updateData:userinfo];
                break;
            }
            case 21:
            case 22:
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                [self showNotication:@"Scrobble Successful."message:[NSString stringWithFormat:@"%@ - %@",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
                //Add History Record
                [self addrecord:[haengine getLastScrobbledActualTitle] Episode:[haengine getLastScrobbledEpisode] Date:[NSDate date]];
                break;
            case 51:
                [self setStatusText:@"Scrobble Status: Can't find title. Retrying in 5 mins..."];
                [self showNotication:@"Scrobble Unsuccessful." message:[NSString stringWithFormat:@"Couldn't find %@.", [haengine getFailedTitle]]];
                break;
            case 52:
            case 53:
                [self showNotication:@"Scrobble Unsuccessful." message:@"Retrying in 5 mins..."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
                break;
            case 54:
                [self showNotication:@"Scrobble Unsuccessful." message:@"Check user credentials in Preferences. You may need to login again."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. User credentials might have expired."];
                break;
            case 55:
                [self setStatusText:@"Scrobble Status: No internet connection."];
                break;
            default:
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([haengine getSuccess] == 1) {
				[findtitle setHidden:true];
                [self setStatusMenuTitleEpisode:[haengine getLastScrobbledActualTitle] episode:[haengine getLastScrobbledEpisode]];
                if (status != 3 && [haengine getConfirmed]){
                    // Show normal info
                    [self updateLastScrobbledTitleStatus:false];
                    //Enable Update Status functions
                    [updatetoolbaritem setEnabled:YES];
                    [updatedupdatestatus setEnabled:YES];
                    [confirmupdate setHidden:YES];
                }
                else{
                    // Show that user needs to confirm update
                    [self updateLastScrobbledTitleStatus:true];
                        [confirmupdate setHidden:NO];
                    if ([haengine getisNewTitle]) {
                        // Disable Update Status functions for new and unconfirmed titles.
                        [updatecorrect setAutoenablesItems:NO];
                        [updatetoolbaritem setEnabled:NO];
                        [updatedupdatestatus setEnabled:NO];
                    }
                }
                [sharetoolbaritem setEnabled:YES];
                [correcttoolbaritem setEnabled:YES];
                // Show hidden menus
                [self unhideMenus];
                NSDictionary * ainfo = [haengine getLastScrobbledInfo];
                if (ainfo !=nil) { // Checks if Hachidori already populated info about the just updated title.
                    [self showAnimeInfo:ainfo];
                    [self generateShareMenu];
                }
            }
            // Enable Menu Items
            scrobbleractive = false;
            [updatenow setEnabled:YES];
            [togglescrobbler setEnabled:YES];
            [statusMenu setAutoenablesItems:YES];
            [confirmupdate setEnabled:YES];
            [findtitle setEnabled:YES];
            [updatenow setTitle:@"Update Now"];
	});
    });
    
    }
}
-(void)starttimer {
	NSLog(@"Timer Started.");
    timer = [NSTimer scheduledTimerWithTimeInterval:300
                                             target:self
                                           selector:@selector(firetimer:)
                                           userInfo:nil
                                            repeats:YES];
    if (previousfiredate != nil) {
        NSLog(@"Resuming Timer");
        float pauseTime = -1*[pausestart timeIntervalSinceNow];
        [timer setFireDate:[previousfiredate initWithTimeInterval:pauseTime sinceDate:previousfiredate]];
        pausestart = nil;
        previousfiredate = nil;
    }

}
-(void)stoptimer {
	NSLog(@"Pausing Timer.");
	//Stop Timer
	[timer invalidate];
    //Set Previous Fire and Pause Times
    pausestart = [NSDate date];
    previousfiredate = [timer fireDate];
}

-(IBAction)updatenow:(id)sender{
    if ([Utility checktoken]) {
        [self firetimer:nil];
    }
    else
        [self showNotication:@"Hachidori" message:@"Please log in with your account in Preferences before using this program"];
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
    if (!confirmupdate.hidden && [haengine getisNewTitle])
        [fsdialog setCorrection:NO];
    else
        [fsdialog setCorrection:YES];
    if (!findtitle.hidden) {
        //Use failed title
         [fsdialog setSearchField:[haengine getFailedTitle]];
    }
    else{
        //Get last scrobbled title
        [fsdialog setSearchField:[haengine getLastScrobbledTitle]];
    }
    // Set search field to search for the last scrobbled detected title
    [fsdialog setSearchField:[haengine getLastScrobbledTitle]];
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
				if (!findtitle.hidden) {
					 [self addtoExceptions:[haengine getFailedTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[[fsdialog getSelectedTotalEpisodes] intValue]];
				}
				else{
					 [self addtoExceptions:[haengine getLastScrobbledTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID] threshold:[[fsdialog getSelectedTotalEpisodes] intValue]];
				}
                if([fsdialog getdeleteTitleonCorrection]){
                    if([haengine removetitle:[haengine getAniID]]){
                        NSLog(@"Removal Successful");
                    }
                }
                NSLog(@"Updating corrected title...");
                int status;
				if (!findtitle.hidden) {
					status = [haengine scrobbleagain:[haengine getFailedTitle] Episode:[haengine getFailedEpisode]];
				}
				else{
					[haengine scrobbleagain:[haengine getLastScrobbledTitle] Episode:[haengine getLastScrobbledEpisode]];
				}
					
                switch (status) {
                    case 1:
                    case 2:
                    case 21:
                    case 22:{
                        [self setStatusText:@"Scrobble Status: Correction Successful..."];
                        [self showNotication:@"Hachidori" message:@"Correction was successful"];
                        [self setStatusMenuTitleEpisode:[haengine getLastScrobbledActualTitle] episode:[haengine getLastScrobbledEpisode]];
                        [self updateLastScrobbledTitleStatus:false];
	                    if (!findtitle.hidden) {
	                        //Unhide menus and enable functions on the toolbar
	                        [self unhideMenus];
	                        [sharetoolbaritem setEnabled:YES];
	                        [correcttoolbaritem setEnabled:YES];
	                    }
     
                        //Show Anime Correct Information
                        NSDictionary * ainfo = [haengine getLastScrobbledInfo];
                        [self showAnimeInfo:ainfo];
                        [confirmupdate setHidden:true];
						//Regenerate Share Items
						[self generateShareMenu];
                        break;
                    }
                    default:
                        [self setStatusText:@"Scrobble Status: Correction unsuccessful..."];
                        [self showNotication:@"Hachidori" message:@"Correction was not successful."];
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
		[historywindow makeKeyAndOrderFront:nil];

}
-(void)addrecord:(NSString *)title
		 Episode:(NSString *)episode
			Date:(NSDate *)date;
{
// Add scrobble history record to the SQLite Database via Core Data
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObject *obj = [NSEntityDescription 
							insertNewObjectForEntityForName :@"History" 
							inManagedObjectContext: moc];
	// Set values in the new record
	[obj setValue:title forKey:@"Title"];
	[obj setValue:episode forKey:@"Episode"];
	[obj setValue:date forKey:@"Date"];

}
-(IBAction)clearhistory:(id)sender
{
	// Set Up Prompt Message Window
	NSAlert * alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"No"];
	[alert setMessageText:@"Are you sure you want to clear the Scrobble History?"];
	[alert setInformativeText:@"Once done, this action cannot be undone."];
	// Set Message type to Warning
	[alert setAlertStyle:NSWarningAlertStyle];
	// Show as Sheet on historywindow
	[alert beginSheetModalForWindow:historywindow 
					  modalDelegate:self
					 didEndSelector:@selector(clearhistoryended:code:conext:)
						contextInfo:NULL];

}
-(void)clearhistoryended:(NSAlert *)alert
					code:(int)echoice
				  conext:(void *)v
{
	if (echoice == 1000) {
		// Remove All Data
		NSManagedObjectContext *moc = [self managedObjectContext];
		NSFetchRequest * allHistory = [[NSFetchRequest alloc] init];
		[allHistory setEntity:[NSEntityDescription entityForName:@"History" inManagedObjectContext:moc]];
		
		NSError * error = nil;
		NSArray * histories = [moc executeFetchRequest:allHistory error:&error];
		//error handling goes here
		for (NSManagedObject * history in histories) {
			[moc deleteObject:history];
		}
	}
	
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
        [lastupdateheader setTitle:@"Last Scrobbled:"];
        [self setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - Episode %@ playing from %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode], [haengine getLastScrobbledSource]]];
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
-(NSManagedObjectModel *)getObjectModel{
    return managedObjectModel;
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
    [showscore setStringValue:[NSString stringWithFormat:@"%i", [haengine getScore]]];
    [episodefield setStringValue:[NSString stringWithFormat:@"%i", [haengine getCurrentEpisode]]];
    if ([[haengine getTotalEpisodes] intValue] !=0) {
        [epiformatter setMaximum:[NSNumber numberWithInt:[[haengine getTotalEpisodes] intValue]]];
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
        BOOL result = [haengine updatestatus:[haengine getAniID] episode:tmpepisode score:[showscore floatValue] watchstatus:[showstatus titleOfSelectedItem] notes:[[notes textStorage] string] isPrivate:[isPrivate state]];
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

#pragma mark Notification Center and Title/Update Confirmation

-(void)showNotication:(NSString *)title message:(NSString *) message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = nil;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
-(void)showConfirmationNotication:(NSString *)title message:(NSString *) message updateData:(NSDictionary *)d{
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
        NSString * title = [notification.userInfo objectForKey:@"title"];
        NSString * episode = [notification.userInfo objectForKey:@"episode"];
        // Only confirm update if the title and episode is the same with the last scrobbled.
        if ([[haengine getLastScrobbledTitle] isEqualToString:title] && [episode intValue] == [[haengine getLastScrobbledEpisode] intValue]) {
            //Confirm Update
            [self confirmupdate];
        }
        else{
            return;
        }
    }
}
-(IBAction)confirmupdate:(id)sender{
    [self confirmupdate];
}
-(void)confirmupdate{
    BOOL success = [haengine confirmupdate];
    if (success) {
        [self updateLastScrobbledTitleStatus:false];
        [self addrecord:[haengine getLastScrobbledActualTitle] Episode:[haengine getLastScrobbledEpisode] Date:[NSDate date]];
        [confirmupdate setHidden:YES];
        [self setStatusText:@"Scrobble Status: Update was successful."];
        [self showNotication:@"Hachidori" message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",[haengine getLastScrobbledActualTitle],[haengine getLastScrobbledEpisode]]];
        if ([haengine getisNewTitle]) {
            // Enable Update Status functions for new and unconfirmed titles.
            [confirmupdate setHidden:YES];
			[updatetoolbaritem setEnabled:YES];
            [updatedupdatestatus setEnabled:YES];
        }
    }
    else{
        [self showNotication:@"Hachidori" message:@"Failed to confirm update. Please try again later."];
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
    [self appendToAnimeInfo:[NSString stringWithFormat:@"%@", [d objectForKey:@"title"]]];
    if ([d objectForKey:@"alternate_title"] != [NSNull null] && [[NSString stringWithFormat:@"%@", [d objectForKey:@"alternate_title"]] length] >0) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Also known as %@", [d objectForKey:@"alternate_title"]]];
    }
    [self appendToAnimeInfo:@""];
    //Description
    NSString * anidescription = [d objectForKey:@"synopsis"];
    anidescription = [anidescription stripHtml]; //Removes HTML tags
    [self appendToAnimeInfo:@"Description"];
    [self appendToAnimeInfo:anidescription];
    //Meta Information
    [self appendToAnimeInfo:@""];
    [self appendToAnimeInfo:@"Other Information"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Start Date: %@", [d objectForKey:@"started_airing"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Airing Status: %@", [d objectForKey:@"status"]]];
    if ([d objectForKey:@"finished_airing"] != [NSNull null]) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Finished Airing: %@", [d objectForKey:@"finished_airing"]]];
    }
    if ([d objectForKey:@"episode_count"] != [NSNull null]){
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %@", [d objectForKey:@"episode_count"]]];
    }
    else{
        [self appendToAnimeInfo:@"Episodes: Unknown"];
    }
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Show Type: %@", [d objectForKey:@"show_type"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Age Rating: %@", [d objectForKey:@"age_rating"]]];
    //Image
    NSImage * dimg = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [d objectForKey:@"cover_image"]]]]; //Downloads Image
    [img setImage:dimg]; //Get the Image for the title
    // Clear Anime Info so that Hachidori won't attempt to retrieve it if the same episode and title is playing
    [haengine clearAnimeInfo];
}

- (void)appendToAnimeInfo:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
        [[animeinfo textStorage] appendAttributedString:attr];
    });
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
    shareItems = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@ - %@", [haengine getLastScrobbledActualTitle], [haengine getLastScrobbledEpisode] ], [NSURL URLWithString:[NSString stringWithFormat:@"http://hummingbird.me/anime/%@", [haengine getAniID]]] ,nil];
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

@end
