//
//  HistoryWindow.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2015/02/03.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface HistoryWindow : NSWindowController <NSWindowDelegate>{
    IBOutlet NSArrayController * arraycontroller;
    IBOutlet NSTableView * historytable;
}
@property (nonatomic, readonly)  NSManagedObjectContext *managedObjectContext;
+ (void)addrecord:(NSString *)title
         Episode:(NSString *)episode
            Date:(NSDate *)date;
@end
