//
//  ExceptionsPref.h
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"
#import "FixSearchDialog.h"
@class FixSearchDialog;
@interface ExceptionsPref : NSViewController <MASPreferencesViewController>{
    IBOutlet NSArrayController * arraycontroller;
    IBOutlet NSTableView * tb;
    FixSearchDialog *fsdialog;
    NSWindow *prefw;
    NSString *detectedtitle;
}
@property(strong) FixSearchDialog *fsdialog;
@end
