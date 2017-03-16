//
//  GeneralPrefController.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>
#import <MASPreferences/MASPreferences.h>



@interface GeneralPrefController : NSViewController <MASPreferencesViewController> {
    IBOutlet NSButton * disablenewtitlebar;
    IBOutlet NSButton * disablevibarency;
    IBOutlet NSButton * startatlogin;
    IBOutlet NSProgressIndicator * indicator;
    IBOutlet NSButton * updateexceptionsbtn;
    IBOutlet NSButton * updateexceptionschk;
}
@end
