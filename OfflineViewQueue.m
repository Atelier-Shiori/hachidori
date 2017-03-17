//
//  OfflineViewQueue.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/08.
//  Copyright 2009-2017 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "OfflineViewQueue.h"

@interface OfflineViewQueue ()

@end

@implementation OfflineViewQueue
@dynamic managedObjectContext;
- (NSManagedObjectContext *)managedObjectContext {
    MAL_Updater_OS_XAppDelegate *appDelegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    return appDelegate.managedObjectContext;
}
-(id)init{
    self = [super initWithWindowNibName:@"OfflineViewQueue"];
    if(!self)
        return nil;
    return self;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
-(IBAction)clearqueue:(id)sender
{
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert setMessageText:@"Are you sure you want to clear the Offline Queue?"];
    [alert setInformativeText:@"Once done, this action cannot be undone."];
    // Set Message type to Warning
    [alert setAlertStyle:NSWarningAlertStyle];
    // Show as Sheet on historywindow
    [alert beginSheetModalForWindow:self.window
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
        NSFetchRequest * allQueue = [[NSFetchRequest alloc] init];
        [allQueue setEntity:[NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc]];
        
        NSError * error = nil;
        NSArray * queue = [moc executeFetchRequest:allQueue error:&error];
        //error handling goes here
        for (NSManagedObject * item in queue) {
            [moc deleteObject:item];
        }
        [moc save:&error];
        // Clear Core Data Objects from Memory
        [moc reset];
    }
    
}

@end
