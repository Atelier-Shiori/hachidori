//
//  GeneralPrefController.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>
#import <MASPreferences/MASPreferences.h>



@interface GeneralPrefController : NSViewController <MASPreferencesViewController>
@property (strong) IBOutlet NSButton * disablenewtitlebar;
@property (strong) IBOutlet NSButton * disablevibarency;
@property (strong) IBOutlet NSButton * startatlogin;
@property (strong) IBOutlet NSProgressIndicator * indicator;
@property (strong) IBOutlet NSButton * updateexceptionsbtn;
@property (strong) IBOutlet NSButton * updateexceptionschk;
@property (strong) IBOutlet NSButton *animerealtionschk;
@property (strong) IBOutlet NSButton *updateanimerelationsbtn;
@property (strong) IBOutlet NSProgressIndicator *animerelationindicator;
@end
