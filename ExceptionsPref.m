//
//  ExceptionsPref.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "ExceptionsPref.h"
#import "Recognition.h"

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
-(void)awakeFromNib{
    [arraycontroller setManagedObjectContext:self.managedObjectContext];
    [arraycontroller prepareContent];
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
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"mkv", @"mp4", @"avi", @"ogm", @"rm", @"rmvb", @"wmv", @"divx", @"mov", @"flv", @"mpg", @"3gp", nil]];
    [op setMessage:@"Please select a media file you want to create an exception for."];
    [op beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        //Close Open Window
        [op orderOut:nil];
        NSDictionary * d = [[Recognition alloc] recognize:[[op URL] path]];
        detectedtitle = [d objectForKey:@"title"];
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
        NSManagedObjectContext * moc = self.managedObjectContext;
        NSError * error = nil;
        // Add to Cache in Core Data
        NSManagedObject *obj = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"Exceptions"
                                    inManagedObjectContext: moc];
        // Set values in the new record
        [obj setValue:detectedtitle forKey:@"detectedTitle"];
        [obj setValue:[fsdialog getSelectedTitle] forKey:@"correctTitle"];
        [obj setValue:[fsdialog getSelectedAniID] forKey:@"id"];
        [obj setValue:[NSNumber numberWithInt:0] forKey:@"episodeOffset"];
        [obj setValue:[NSNumber numberWithInt:[[fsdialog getSelectedTotalEpisodes] intValue]] forKey:@"episodethreshold"];
        //Save
        [moc save:&error];
        // Load present cache data
        NSFetchRequest * allCache = [[NSFetchRequest alloc] init];
        [allCache setEntity:[NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc]];
        
        error = nil;
        NSArray * caches = [moc executeFetchRequest:allCache error:&error];
        if (caches.count > 0) {
            //Check Cache to remove conflicts
            for (NSManagedObject * cacheentry in caches) {
                if ([detectedtitle isEqualToString:(NSString *)[cacheentry valueForKey:@"detectedTitle"]]) {
                    [moc deleteObject:cacheentry];
                    break;
                }
            }
            //Save
            [moc save:&error];
        }
    }
    else{
    }
    fsdialog = nil;
    detectedtitle = nil;
}
-(IBAction)removeSlection:(id)sender{
    //Remove Selected Object
    [arraycontroller removeObject:[[arraycontroller selectedObjects] objectAtIndex:0]];
}
-(IBAction)importList:(id)sender{
    // Set Open Dialog to get json file.
    NSOpenPanel * op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"json", @"JSON file", nil]];
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
        NSManagedObjectContext * moc = self.managedObjectContext;
        for (NSDictionary *d in a) {
            NSString * detectedtitlea = [d objectForKey:@"detectedtitle"];
            int doffset;
            if ([d objectForKey:@"offset"] != nil) {
                doffset = [(NSNumber *)[d objectForKey:@"offset"] intValue];
            }
            else{
                doffset = 0;
            }
            BOOL exists = [self checkifexists:detectedtitlea offset:doffset correcttitle:(NSString *)[d objectForKey:@"correcttitle"]];
            // Check to see if it exists on the list already
            if (exists) {
                //Check next title
                continue;
            }
            else{
                NSError * error = nil;
                // Add to Cache in Core Data
                NSManagedObject *obj = [NSEntityDescription
                                            insertNewObjectForEntityForName:@"Exceptions"
                                            inManagedObjectContext: moc];
                // Set values in the new record
                [obj setValue:[d objectForKey:@"detectedtitle"] forKey:@"detectedTitle"];
                [obj setValue:[d objectForKey:@"correcttitle"] forKey:@"correctTitle"];
                [obj setValue:[d objectForKey:@"showid"] forKey:@"id"];
                [obj setValue:[NSNumber numberWithInt:doffset] forKey:@"episodeOffset"];
                if ([d objectForKey:@"threshold"] != nil) {
                    [obj setValue:[d objectForKey:@"threshold"] forKey:@"episodethreshold"];
                }
                else{
                    [obj setValue:[NSNumber numberWithInt:0] forKey:@"episodethreshold"];
                }
                //Save
                [moc save:&error];
                // Load present cache data
                NSFetchRequest * allCache = [[NSFetchRequest alloc] init];
                [allCache setEntity:[NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc]];
                
                error = nil;
                NSArray * caches = [moc executeFetchRequest:allCache error:&error];
                if (caches.count > 0) {
                    //Check Cache to remove conflicts
                    NSString * dtitle = (NSString *)[d objectForKey:@"detectedtitle"];
                    for (NSManagedObject * cacheentry in caches) {
                        if ([dtitle isEqualToString:(NSString *)[cacheentry valueForKey:@"detectedTitle"]]) {
                            [moc deleteObject:cacheentry];
                            break;
                        }
                    }
                    //Save
                    [moc save:&error];
                }
            }
        }
    }];

    
}
-(IBAction)exportList:(id)sender{
    // Save the json file containing titles
    NSSavePanel * sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:[NSArray arrayWithObjects:@"json", @"JSON file", nil]];
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
            NSDictionary * d = [[NSDictionary alloc] initWithObjectsAndKeys:[o valueForKey:@"detectedTitle"], @"detectedtitle", [o valueForKey:@"correctTitle"], @"correcttitle", [o valueForKey:@"id"], @"showid", [o valueForKey:@"episodeOffset"], @"offset", [o valueForKey:@"episodethreshold"], @"threshold", nil];
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
        if ([detectedtitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]] && eoffset == offset) {
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
        NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys: [[op URL] path], @"directory", nil];
        [ignorearraycontroller addObject:entry];
    }];
}
-(IBAction)removeDirectory:(id)sender{
    //Remove Selected Object
    [ignorearraycontroller removeObject:[[ignorearraycontroller selectedObjects] objectAtIndex:0]];
}
#pragma mark Title Ignore
-(IBAction)addFifleNameIgnoreRule:(id)sender{
    NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys: @"", @"rule", nil];
    [ignorefilenamearraycontroller addObject:entry];
    // Selection Workaround
    int c = [[NSArray arrayWithArray:[ignorefilenamearraycontroller arrangedObjects]] count];
    if(c > 0){
        [iftb editColumn:0 row:c-1 withEvent:nil select:YES];
    }
}
-(IBAction)removeFileNameIgnoreRule:(id)sender{
    //Remove Selected Object
    [ignorefilenamearraycontroller removeObject:[[ignorefilenamearraycontroller selectedObjects] objectAtIndex:0]];
}

@end
