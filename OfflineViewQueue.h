//
//  OfflineViewQueue.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/08.
//  Copyright 2009-2017 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "MAL_Updater_OS_XAppDelegate.h"

@interface OfflineViewQueue : NSWindowController{
    	NSManagedObjectContext *managedObjectContext;
    MAL_Updater_OS_XAppDelegate * delegate;
}
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@end
