//
//  OfflineViewQueue.h
//  Hachidori
//
//  Created by 桐間紗路 on 2017/01/08.
//  Copyright 2009-2017 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface OfflineViewQueue : NSWindowController{
    NSManagedObjectContext *managedObjectContext;
}
@property (strong) AppDelegate * delegate;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@end
