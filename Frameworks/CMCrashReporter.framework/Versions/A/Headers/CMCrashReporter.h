//
//  CMCrashReporter.h
//  CMCrashReporter-App
//
//  Created by Jelle De Laender on 20/01/08.
//  Copyright 2008 CodingMammoth. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CMCrashReporterGlobal.h"
#import "CMCrashReporterWindow.h"

@interface CMCrashReporter : NSObject
{

}
+ (void)check;
+ (NSArray *)getReports;
@end
