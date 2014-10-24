//
//  GeneralPrefController.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"


@interface GeneralPrefController : NSViewController <MASPreferencesViewController> {
}
-(void)showsheetmessage:(NSString *)message
		   explaination:(NSString *)explaination;

@end
