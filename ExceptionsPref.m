//
//  ExceptionsPref.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "ExceptionsPref.h"
#import "Recognition.h"
#import "ExceptionsCache.h"

@interface ExceptionsPref ()

@end

@implementation ExceptionsPref
@synthesize fsdialog;
@dynamic managedObjectContext;

- (NSManagedObjectContext *)managedObjectContext {
   AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    return appDelegate.managedObjectContext;
}
- (id)init
{
    return [super initWithNibName:@"ExceptionsPref" bundle:nil];
}
#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"ExceptionsPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"rules.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Exceptions", @"Toolbar item name for the Exceptions spreference pane");
}
#pragma mark Anime Exceptions List Functions
-(IBAction)addTitle:(id)sender{
    //Obtain Detected Title from Media File
    NSOpenPanel * op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:@[@"mkv", @"mp4", @"avi", @"ogm", @"rm", @"rmvb", @"wmv", @"divx", @"mov", @"flv", @"mpg", @"3gp"]];
    [op setMessage:@"Please select a media file you want to create an exception for."];
    [op beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        //Close Open Window
        [op orderOut:nil];
        NSDictionary * d = [[Recognition alloc] recognize:[[op URL] path]];
        detectedtitle = d[@"title"];
        if ([self checkifexists:detectedtitle offset:0 correcttitle:nil]) {
            // Exists, don't do anything
            return;
        }
        fsdialog = [FixSearchDialog new];
        [fsdialog setCorrection:false];
        [fsdialog setSearchField:detectedtitle];
        [NSApp beginSheet:[fsdialog window]
           modalForWindow:[[self view] window] modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }];
}
-(void)correctionDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1){
        // Check if correct title exists
        if ([self checkifexists:detectedtitle offset:0 correcttitle:[fsdialog getSelectedTitle]]) {
            // Exists, don't do anything
            return;
        }
        // Add to Exceptions
        [ExceptionsCache addtoExceptions:detectedtitle correcttitle:[fsdialog getSelectedTitle] aniid:[fsdialog getSelectedAniID] threshold:[fsdialog getSelectedTotalEpisodes] offset:0];
        //Check Cache
        [ExceptionsCache checkandRemovefromCache:detectedtitle];
    }
    // Refetch Exceptions Data
    [arraycontroller fetch:self];
    fsdialog = nil;
    detectedtitle = nil;
}
-(IBAction)removeSlection:(id)sender{
    //Remove Selected Object
    [arraycontroller removeObject:[arraycontroller selectedObjects][0]];
}
-(IBAction)importList:(id)sender{
    // Set Open Dialog to get json file.
    NSOpenPanel * op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:@[@"json", @"JSON file"]];
    [op setMessage:@"Please select an exceptions list to import."];
    [op beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        NSURL *Url = [op URL];
        
        // read the file
        NSString * str = [NSString stringWithContentsOfURL:Url
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
        
        NSData *jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        NSArray * a = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        for (NSDictionary *d in a) {
            NSString * detectedtitlea = d[@"detectedtitle"];
            int doffset;
            if (d[@"offset"] != nil) {
                doffset = [(NSNumber *)d[@"offset"] intValue];
            }
            else{
                doffset = 0;
            }
            BOOL exists = [self checkifexists:detectedtitlea offset:doffset correcttitle:(NSString *)d[@"correcttitle"]];
            // Check to see if it exists on the list already
            if (exists) {
                //Check next title
                continue;
            }
            else{
                // Add to Exceptions List
                int threshold;
                if (d[@"threshold"] != nil) {
                    threshold = [(NSNumber *)d[@"threshold"] intValue];
                }
                else{
                    threshold = 0;
                }
                [ExceptionsCache addtoExceptions:d[@"detectedtitle"] correcttitle:d[@"correcttitle"] aniid:d[@"showid"] threshold:threshold offset:doffset];
                //Check Cache
                [ExceptionsCache checkandRemovefromCache:(NSString *)d[@"detectedtitle"]];
            }
            // Refetch Exceptions Data
            [arraycontroller fetch:self];
        }
    }];
}
-(IBAction)exportList:(id)sender{
    // Save the json file containing titles
    NSSavePanel * sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:@[@"json", @"JSON file"]];
    [sp setMessage:@"Where do you want to save your exception list?"];
    [sp setNameFieldStringValue:@"Exceptions List.json"];
    [sp beginSheetModalForWindow:[[self view]window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        NSURL *url = [sp URL];
        //Create JSON string from array controller
        NSError *error;
        NSMutableArray * jsonOutput = [[NSMutableArray alloc] init];
        for (NSManagedObject * o in arraycontroller.arrangedObjects) {
            @autoreleasepool {
            NSDictionary * d = @{@"detectedtitle": [o valueForKey:@"detectedTitle"], @"correcttitle": [o valueForKey:@"correctTitle"], @"showid": [o valueForKey:@"id"], @"offset": [o valueForKey:@"episodeOffset"], @"threshold": [o valueForKey:@"episodethreshold"]};
            [jsonOutput addObject:d];
            }
        }
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonOutput
                                                           options:0
                                                             error:&error];
        if (!jsonData) {
            return;
        } else {
            NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            
            
            //write JSON to file
            BOOL wresult = [JSONString writeToURL:url
                                       atomically:YES
                                         encoding:NSUTF8StringEncoding
                                            error:&error];
            if (! wresult) {
                NSLog(@"Export Failed: %@", error);
            }
        }
    }];
}
#pragma mark Misc Functions
-(IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Correction-Exception-Help"]];
}
-(BOOL)checkifexists:(NSString *) title offset:(int)offset correcttitle:(NSString *)ctitle{
    // Checks if a title is already on the exception list
    NSArray * a = [arraycontroller arrangedObjects];
    for (NSManagedObject * entry in a) {
        int eoffset = [(NSNumber *)[entry valueForKey:@"episodeOffset"] intValue];
        if ([title isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]] && eoffset == offset) {
            if (ctitle == nil) {
                return true;
            }
            else if(ctitle != nil && [ctitle isEqualToString:(NSString *)[entry valueForKey:@"correctTitle"]]){
               return true;
            }
        }
    }
    return false;
}
#pragma mark Ignore List
-(IBAction)addDirectory:(id)sender{
    //Selects directory to ignore
    NSOpenPanel * op = [NSOpenPanel openPanel];
    [op setCanChooseDirectories:YES];
    [op setCanCreateDirectories:NO];
    [op setCanChooseFiles:NO];
    [op setMessage:@"Please a directory for Hachidori to ignore."];
    [op beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        NSDictionary * entry = @{@"directory": [[op URL] path]};
        [ignorearraycontroller addObject:entry];
    }];
}
-(IBAction)removeDirectory:(id)sender{
    //Remove Selected Object
    [ignorearraycontroller removeObject:[ignorearraycontroller selectedObjects][0]];
}
#pragma mark Title Ignore
-(IBAction)addFifleNameIgnoreRule:(id)sender{
    NSDictionary * entry = @{@"rule": @""};
    [ignorefilenamearraycontroller addObject:entry];
    // Selection Workaround
    int c = (int) [[NSArray arrayWithArray:[ignorefilenamearraycontroller arrangedObjects]] count];
    if(c > 0){
        [iftb editColumn:0 row:c-1 withEvent:nil select:YES];
    }
}
-(IBAction)removeFileNameIgnoreRule:(id)sender{
    //Remove Selected Object
    [ignorefilenamearraycontroller removeObject:[ignorefilenamearraycontroller selectedObjects][0]];
}

@end
