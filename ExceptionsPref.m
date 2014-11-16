//
//  ExceptionsPref.m
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//
//

#import "ExceptionsPref.h"

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
    return [NSImage imageNamed:@"edit.tiff"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Exceptions", @"Toolbar item name for the Exceptions spreference pane");
}
-(IBAction)addTitle:(id)sender{
    fsdialog = [FixSearchDialog new];
    [[[self view] window] beginSheet:[fsdialog window] completionHandler:^(NSModalResponse returnCode){
        if (returnCode == NSModalResponseOK) {
            NSLog(@"OK");
            NSLog(@"Selected Title %@", [fsdialog getSelectedTitle]);
        }
        else{
            NSLog(@"Cancel");
        }
        fsdialog = nil;
    }];
}
-(IBAction)removeSlection:(id)sender{
    //Remove Selected Object
    [arraycontroller removeObject:[[arraycontroller selectedObjects] objectAtIndex:0]];
}
-(IBAction)importList:(id)sender{
    // get the url of a .txt file
    NSOpenPanel * op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"json", @"JSON file", nil]];
    [op setTitle:@"Import Exceptions List"];
    NSInteger result = [op runModal];
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
    NSArray * b = [arraycontroller arrangedObjects];
    for (NSDictionary *d in a) {
        NSString * detectedtitlea = [d objectForKey:@"detectedtitle"];
        BOOL exists = false;
        // Check to see if it exists on the list already
        for (NSDictionary * e in b){
            NSString * detectedtitleb = [e objectForKey:@"detectedtitle"];
            if ([detectedtitlea isEqualToString:detectedtitleb]) {
                exists = true;
                break;
            }
        }
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
    
}
-(IBAction)exportList:(id)sender{
    // Get the file url
    NSSavePanel * sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:[NSArray arrayWithObjects:@"json", @"JSON file", nil]];
    [sp setTitle:@"Export Exceptions List"];
    [sp setNameFieldStringValue:@"Exceptions List.json"];
    NSInteger result = [sp runModal];
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
}
-(IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Correction-Exception-Help"]];
}

@end
