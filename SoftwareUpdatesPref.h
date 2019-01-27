//
//  SoftwareUpdatesPref.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>

@interface SoftwareUpdatesPref : NSViewController <MASPreferencesViewController>
@property (strong) IBOutlet NSButton *betacheck;

@end
