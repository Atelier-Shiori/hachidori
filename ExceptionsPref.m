//
//  ExceptionsPref.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "ExceptionsPref.h"
#import "Recognition.h"

@interface ExceptionsPref ()

@end

@implementation ExceptionsPref
@synthesize fsdialog;
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
    return [NSImage imageNamed:@"rules.tif"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Exceptions", @"Toolbar item name for the Exceptions spreference pane");
}
-(IBAction)addTitle:(id)sender{
    //Obtain Detected Title from Media File
    NSOpenPanel * op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"mkv", @"mp4", @"avi", @"ogm", nil]];
    [op setMessage:@"Please select a media file you want to create an exception for."];
    [op beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        //Close Open Window
        [op orderOut:nil];
        NSDictionary * d = [[Recognition alloc] recognize:[[op URL] path]];
        detectedtitle = [d objectForKey:@"title"];
        if ([self checkifexists:detectedtitle]) {
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
        // Add to Array Controller
        NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys:detectedtitle, @"detectedtitle", [fsdialog getSelectedTitle] ,@"correcttitle", [fsdialog getSelectedAniID], @"showid", nil];
        [arraycontroller addObject:entry];
        //Check if the title exists in the cache. If so, remove it
        NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
        if (cache.count > 0) {
            for (int i=0; i<[cache count]; i++) {
                NSDictionary * d = [cache objectAtIndex:i];
                NSString * title = [d objectForKey:@"detectedtitle"];
                if ([title isEqualToString:detectedtitle]) {
                    NSLog(@"%@ found in cache, remove!", title);
                    [cache removeObject:d];
                    break;
                }
            }
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
        for (NSDictionary *d in a) {
            NSString * detectedtitlea = [d objectForKey:@"detectedtitle"];
            BOOL exists = [self checkifexists:detectedtitlea];
            // Check to see if it exists on the list already
            if (exists) {
                //Check next title
                continue;
            }
            else{
                //Import Object
                [arraycontroller addObject:d];
                //Check if the title exists in the cache. If so, remove it
                NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
                if (cache.count > 0) {
                    for (int i=0; i<[cache count]; i++) {
                        NSDictionary * d = [cache objectAtIndex:i];
                        NSString * title = [d objectForKey:@"detectedtitle"];
                        if ([title isEqualToString:detectedtitlea]) {
                            NSLog(@"%@ found in cache, remove!", title);
                            [cache removeObject:d];
                            break;
                        }
                    }
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
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[arraycontroller arrangedObjects]
                                                           options:0
                                                             error:&error];
        if (!jsonData) {
            return;
        } else {
            NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            
            
            //write JSON to file
            BOOL wresult = [JSONString writeToURL:url
                                       atomically:YES
                                         encoding:NSASCIIStringEncoding
                                            error:NULL];
            if (! wresult) {
                NSLog(@"Export Failed");
            }
        }
    }];
}
-(IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Correction-Exception-Help"]];
}
-(BOOL)checkifexists:(NSString *) title{
    // Checks if a title is already on the exception list
    NSArray * a = [arraycontroller arrangedObjects];
    for (NSDictionary * d in a){
        NSString * dt = [d objectForKey:@"detectedtitle"];
        if ([title isEqualToString:dt]) {
            return true;
        }
    }
    return false;
}

@end
