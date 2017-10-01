//
//  HistoryWindow.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2015/02/03.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "HistoryWindow.h"

@implementation HistoryWindow

@synthesize historytable;
@synthesize arraycontroller;
@dynamic managedObjectContext;

- (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    return appDelegate.managedObjectContext;
}
- (instancetype)init {
    self = [super initWithWindowNibName:@"HistoryWindow"];
    if(!self)
        return nil;
    return self;
}
- (void)awakeFromNib {
    arraycontroller.managedObjectContext = self.managedObjectContext;
    [arraycontroller prepareContent];
    historytable.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"Date" ascending:NO]];
    arraycontroller.sortDescriptors = historytable.sortDescriptors;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

}
+ (void)addrecord:(NSString *)title
         Episode:(NSString *)episode
            Date:(NSDate *)date {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Add scrobble history record to the SQLite Database via Core Data
        AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
        NSManagedObjectContext *moc = appDelegate.managedObjectContext;
        NSManagedObject *obj = [NSEntityDescription
                                insertNewObjectForEntityForName :@"History"
                                inManagedObjectContext: moc];
        // Set values in the new record
        [obj setValue:title forKey:@"Title"];
        [obj setValue:episode forKey:@"Episode"];
        [obj setValue:date forKey:@"Date"];
        [moc save:nil];
    });
}
- (IBAction)clearhistory:(id)sender {
    // Set Up Prompt Message Window
    NSAlert * alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert setMessageText:NSLocalizedString(@"Are you sure you want to clear the Scrobble History?",nil)];
    [alert setInformativeText:NSLocalizedString(@"Once done, this action cannot be undone.",nil)];
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
                  conext:(void *)v {
    if (echoice == 1000) {
        // Remove All Data
        NSManagedObjectContext *moc = self.managedObjectContext;
        NSFetchRequest * allHistory = [[NSFetchRequest alloc] init];
        allHistory.entity = [NSEntityDescription entityForName:@"History" inManagedObjectContext:moc];
        
        NSError * error = nil;
        NSArray * histories = [moc executeFetchRequest:allHistory error:&error];
        //error handling goes here
        for (NSManagedObject * history in histories) {
            [moc deleteObject:history];
        }
    }
}	

@end
