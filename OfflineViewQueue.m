//
//  OfflineViewQueue.m
//  Hachidori
//
//  Created by 桐間紗路 on 2017/01/08.
//  Copyright 2009-2017 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "OfflineViewQueue.h"

@interface OfflineViewQueue ()

@end

@implementation OfflineViewQueue

@synthesize delegate;
@dynamic managedObjectContext;

- (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    return appDelegate.managedObjectContext;
}
- (instancetype)init{
    self = [super initWithWindowNibName:@"OfflineViewQueue"];
    if(!self)
        return nil;
    return self;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)clearqueue:(id)sender
{
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    alert.messageText = @"Are you sure you want to clear the Offline Queue?";
    alert.informativeText = @"Once done, this action cannot be undone.";
    // Set Message type to Warning
    alert.alertStyle = NSWarningAlertStyle;
    // Show as Sheet on historywindow
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(clearhistoryended:code:conext:)
                        contextInfo:NULL];
    
}
- (void)clearhistoryended:(NSAlert *)alert
                    code:(int)echoice
                  conext:(void *)v
{
    if (echoice == 1000) {
        // Remove All Data
        NSManagedObjectContext *moc = self.managedObjectContext;
        NSFetchRequest * allQueue = [[NSFetchRequest alloc] init];
        allQueue.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
        
        NSError * error = nil;
        NSArray * queue = [moc executeFetchRequest:allQueue error:&error];
        //error handling goes here
        for (NSManagedObject * item in queue) {
            [moc deleteObject:item];
        }
        [moc save:&error];
    }
}

@end
