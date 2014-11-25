//
//  AppDelegate.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "AppDelegate.h"
#import "PFMoveApplication.h"
#import "GeneralPrefController.h"
#import "MASPreferencesWindowController.h"
#import "LoginPref.h"
#import "SoftwareUpdatesPref.h"
#import "ExceptionsPref.h"
#import "NSString_stripHtml.h"
#import "DDHotKeyCenter.h"
#import <Carbon/Carbon.h>
#import "FixSearchDialog.h"

@implementation AppDelegate

@synthesize window;
@synthesize historywindow;
@synthesize updatepanel;
@synthesize fsdialog;
/*
 
 Initalization
 
 */
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
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
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
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"searchcache"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"useSearchCache"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"exceptions"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"UseNewRecognitionEngine"]
;
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"ignoredirectories"];
    [defaultValues setObject:[[NSMutableArray alloc] init] forKey:@"IgnoreTitleRules"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"CheckAltTitles"];
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
	[window orderOut:self];
	
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
}
/*
 
 General UI Functions
 
 */
- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[GeneralPrefController alloc] init];
        NSViewController *loginViewController = [[LoginPref alloc] initwithAppDelegate:self];
		NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSViewController *exceptionsViewController = [[ExceptionsPref alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, loginViewController, suViewController, exceptionsViewController, nil];
        
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
		[window orderOut:self]; 
	} else { 
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:self]; 
	} 
}
-(IBAction)share:(id)sender{
   // NSSharingServicePicker *sharePicker = [[NSSharingServicePicker alloc] initWithItems:shareItems];
    //sharePicker.delegate = nil;
    // Show Share Box
    //[sharePicker showRelativeToRect:[sender bounds] ofView:[sharetoolbaritem view] preferredEdge:NSMinYEdge];
}

/*
 
 Timer Functions
 
 */

- (IBAction)toggletimer:(id)sender {
	//Check to see if a token exist
	if (![self checktoken]) {
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([[defaults objectForKey:@"Token"] length] == 0) {
         [self showNotication:@"Hachidori" message:@"Unable to start scrobbling since there is no login. Please verify your login in Preferences."];
	}
	else {
		[self starttimer];
		[togglescrobbler setTitle:@"Stop Scrobbling"];
		[ScrobblerStatus setObjectValue:@"Scrobble Status: Started"];
        //[self showNotication:@"Hachidori" message:@"Auto Scrobble is now turned on."];
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
        [updatenow setTitle:@"Updating..."];
    dispatch_queue_t queue = dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
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
            case 21:
            case 22:
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                [self showNotication:@"Scrobble Successful."message:[NSString stringWithFormat:@"%@ - %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode]]];
                //Add History Record
                [self addrecord:[haengine getLastScrobbledTitle] Episode:[haengine getLastScrobbledEpisode] Date:[NSDate date]];
                //[self setStatusMenuTitleEpisode:[haengine getLastScrobbledTitle] episode:[haengine getLastScrobbledEpisode]];
                break;
            case 51:
                [self setStatusText:@"Scrobble Status: Can't find title. Retrying in 5 mins..."];
                [self showNotication:@"Scrobble Unsuccessful." message:@"Can't find title."];
                break;
            case 52:
            case 53:
                [self showNotication:@"Scrobble Unsuccessful." message:@"Retrying in 5 mins..."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
                break;
            case 54:
                [self showNotication:@"Scrobble Unsuccessful." message:@"Retrying in 5 mins..."];
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
                break;
            case 55:
                [self setStatusText:@"Scrobble Status: Scrobble Failed. Computer is offline."];
                break;
            default:
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([haengine getSuccess] == 1) {
                [updatetoolbaritem setEnabled:YES];
                [sharetoolbaritem setEnabled:YES];
                [correcttoolbaritem setEnabled:YES];
                //Show Last Scrobbled Title and operations */
                [seperator setHidden:NO];
                [lastupdateheader setHidden:NO];
                [updatedtitle setHidden:NO];
                [updatedepisode setHidden:NO];
                [seperator2 setHidden:NO];
                [updatecorrectmenu setHidden:NO];
                [updatedcorrecttitle setHidden:NO];
                [shareMenuItem setHidden:NO];
                [self setStatusMenuTitleEpisode:[haengine getLastScrobbledTitle] episode:[haengine getLastScrobbledEpisode]];
                [self setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - Episode %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode]]];
                [self setStatusToolTip:[NSString stringWithFormat:@"Hachidori - %@ - %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode]]];
                //Show Anime Information
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
    if ([self checktoken]) {
        [self firetimer:nil];
    }
    else
        [self showNotication:@"Hachidori" message:@"Please log in with your account in Preferences before using this program"];
}
-(IBAction)getHelp:(id)sender{
    //Show Help
 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Getting-Started"]];
}
-(void)showAnimeInfo:(NSDictionary *)d{
    //Empty
    [animeinfo setString:@""];
    //Title
    [self appendToAnimeInfo:[NSString stringWithFormat:@"%@", [d objectForKey:@"title"]]];
    if ([[NSString stringWithFormat:@"%@",[d objectForKey:@"alternate_title"]] length] >0) {
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
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %@", [d objectForKey:@"episode_count"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Show Type: %@", [d objectForKey:@"show_type"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Age Rating: %@", [d objectForKey:@"age_rating"]]];
    //Image
    NSImage * dimg = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [d objectForKey:@"cover_image"]]]]; //Downloads Image
    [img setImage:dimg]; //Get the Image for the title
    // Clear Anime Info so that Hachidori won't attempt to retrieve it if the same episode and title is playing
    [haengine clearAnimeInfo];
}
-(BOOL)checktoken{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"Token"] length] == 0) {
        return false;
    }
    else
        return true;
}

/*
 
 Correction/Exception Search
 
 */
-(IBAction)showCorrectionSearchWindow:(id)sender{
    bool isVisible = [window isVisible];
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    [fsdialog setCorrection:YES];
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
                [self addtoExceptions:[haengine getLastScrobbledTitle] newtitle:[fsdialog getSelectedTitle] showid:[fsdialog getSelectedAniID]];
                if([fsdialog getdeleteTitleonCorrection]){
                    if([haengine removetitle:[haengine getAniID]]){
                        NSLog(@"Removal Successful");
                    }
                }
                NSLog(@"Updating corrected title...");
                int status = [haengine scrobbleagain:[haengine getLastScrobbledTitle] Episode:[haengine getLastScrobbledEpisode]];
                switch (status) {
                    case 1:
                    case 21:
                    case 22:{
                        [self setStatusText:@"Scrobble Status: Correction Successful..."];
                        [self showNotication:@"Hachidori" message:@"Correction was successful"];
                        //Show Anime Correct Information
                        NSDictionary * ainfo = [haengine getLastScrobbledInfo];
                        [self showAnimeInfo:ainfo];
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
            NSLog(@"Cancel");
        }
    fsdialog = nil;
    [self enableUpdateItems]; // Enable Update Items
    //Restart Timer
    if (scrobbling == TRUE) {
        [self starttimer];
    }
}
-(void)addtoExceptions:(NSString *)detectedtitle newtitle:(NSString *)title showid:(NSString *)showid{
    //Adds correct title and ID to exceptions list
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *exceptions = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"]];
    //Prevent duplicate
    BOOL exists = false;
    for (NSDictionary * d in exceptions){
        NSString * dt = [d objectForKey:@"detectedtitle"];
        if (![detectedtitle isEqualToString:dt]) {
            NSLog(@"Title exists on Exceptions List");
            exists = true;
            break;
        }
    }
    if (!exists) {
        NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys:detectedtitle, @"detectedtitle", title ,@"correcttitle", showid, @"showid", nil];
        [exceptions addObject:entry];
        [defaults setObject:exceptions forKey:@"exceptions"];
    }
    //Check if the title exists in the cache. If so, remove it
    NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
    if (cache.count > 0) {
        for (int i=0; i<[cache count]; i++) {
            NSDictionary * d = [cache objectAtIndex:i];
            NSString * title = [d objectForKey:@"detectedtitle"];
            if ([title isEqualToString:detectedtitle]) {
                NSLog(@"%@ found in cache, remove!", title);
                [cache removeObject:d];
                [[NSUserDefaults standardUserDefaults] setObject:cache forKey:@"searchcache"];
                break;
            }
        }
    }
}
/*
 
 Scrobble History Window
 
 */

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

/*
 
 StatusIconTooltip, Status Text, Last Scrobbled Title Setters
 
 */

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

/*
 
 Update Status Sheet Window Functions
 
 */

-(IBAction)updatestatus:(id)sender {
    [self showUpdateDialog:[self window]];
    [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
}
-(IBAction)updatestatusmenu:(id)sender{
    [self showUpdateDialog:nil];
}
-(void)showUpdateDialog:(NSWindow *) w{
    // Show Sheet
    [NSApp beginSheet:updatepanel
       modalForWindow:w modalDelegate:self
       didEndSelector:@selector(myPanelDidEnd:returnCode:contextInfo:)
          contextInfo:(void *)nil];
    // Set up UI
    [showtitle setObjectValue:[haengine getLastScrobbledTitle]];
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
- (void)myPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        // Check if Episode field is empty. If so, set it to last scrobbled episode
        NSString * tmpepisode = [episodefield stringValue];
        bool episodechanged;
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
                [self setStatusMenuTitleEpisode:[haengine getLastScrobbledTitle] episode:[haengine getLastScrobbledEpisode]];
                [self setLastScrobbledTitle:[NSString stringWithFormat:@"Last Scrobbled: %@ - Episode %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode]]];
                [self setStatusToolTip:[NSString stringWithFormat:@"Hachidori - %@ - %@",[haengine getLastScrobbledTitle],[haengine getLastScrobbledEpisode]]];
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
/*
 
 Getters
 
 */
-(bool)getisScrobbling{
    return scrobbling;
}
-(bool)getisScrobblingActive{
    return scrobbleractive;
}

//Misc Methods
- (void)appendToAnimeInfo:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
        [[animeinfo textStorage] appendAttributedString:attr];
    });
}
-(void)showNotication:(NSString *)title message:(NSString *) message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = nil;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}
-(void)registerHotkey{
    DDHotKeyCenter *c = [DDHotKeyCenter sharedHotKeyCenter];
    if (![c registerHotKeyWithKeyCode:kVK_ANSI_U modifierFlags:(NSShiftKeyMask|NSCommandKeyMask) target:self action:@selector(hotkeyWithEvent:object:) object:@"scrobblenow"]){}
}
- (void) hotkeyWithEvent:(NSEvent *)hkEvent object:(id)anObject {
    if ([[NSString stringWithFormat:@"%@", anObject] isEqualToString:@"scrobblenow"]) {
        if ([self checktoken] && !panelactive) {
            [self firetimer:nil];
        }
    }
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
}
-(void)enableUpdateItems{
    // Reenables update options
    panelactive = false;
    [updatenow setEnabled:YES];
    [togglescrobbler setEnabled:YES];
    [updatedcorrecttitle setEnabled:YES];
    [updatedupdatestatus setEnabled:YES];
    [updatecorrect setAutoenablesItems:YES];
    [statusMenu setAutoenablesItems:YES];
}
/*
 Share Services
 */
-(void)generateShareMenu{
    //Clear Share Menu
    [shareMenu removeAllItems];
    // Workaround for Share Toolbar Item
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    [shareIcon setImage:[NSImage imageNamed:NSImageNameShareTemplate]];
    [shareIcon setHidden:YES];
    [shareMenu addItem:shareIcon];
    //Generate Items to Share
    shareItems = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@ - %@", [haengine getLastScrobbledTitle], [haengine getLastScrobbledEpisode] ], [NSURL URLWithString:[NSString stringWithFormat:@"http://hummingbird.me/anime/%@", [haengine getAniID]]] ,nil];
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
