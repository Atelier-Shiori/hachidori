//
//  ExceptionsPref.h
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014-2015 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "FixSearchDialog.h"
#import "AppDelegate.h"
@class FixSearchDialog;
@interface ExceptionsPref : NSViewController <MASPreferencesViewController>{
    NSManagedObjectContext *managedObjectContext;
}
@property (strong) IBOutlet NSArrayController * arraycontroller;
@property (strong) IBOutlet NSArrayController * ignorearraycontroller;
@property (strong) IBOutlet NSArrayController * ignorefilenamearraycontroller;
@property (strong) IBOutlet NSTableView * tb;
@property (strong) IBOutlet NSTableView * iftb;
@property (strong) NSString *detectedtitle;
@property int detectedseason;
@property(strong) FixSearchDialog *fsdialog;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@end
