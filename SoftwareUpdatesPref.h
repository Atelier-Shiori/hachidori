//
//  SoftwareUpdatesPref.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"
#import <Sparkle/Sparkle.h>

@interface SoftwareUpdatesPref : NSViewController <MASPreferencesViewController>  {

}
-(IBAction)checkupdates:(id)sender;
@end
