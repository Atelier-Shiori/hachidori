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
-(IBAction)removeSlection:(id)sender{
    //Remove Selected Object
    [arraycontroller removeObject:[[arraycontroller selectedObjects] objectAtIndex:0]];
}
-(IBAction)exportList:(id)sender{
    // Get the file url
    NSSavePanel * sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"json", @"JSON file", nil]];
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

@end
