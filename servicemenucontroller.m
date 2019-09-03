//
//  servicemenucontroller.m
//  Shukofukurou
//
//  Created by 桐間紗路 on 2017/12/18.
//  Copyright © 2017年 MAL Updater OS X Group. All rights reserved.
//

#import "servicemenucontroller.h"
#import "AppDelegate.h"
#import "Hachidori.h"

@implementation servicemenucontroller
- (void)setmenuitemvaluefromdefaults {
    switch ([NSUserDefaults.standardUserDefaults integerForKey:@"currentservice"]) {
        case 0: {
            _kitsuserviceitem.state = NSOnState;
            _anilistserviceitem.state = NSOffState;
            _malserviceitem.state = NSOffState;
            break;
        }
        case 1: {
            _kitsuserviceitem.state = NSOffState;
            _anilistserviceitem.state = NSOnState;
            _malserviceitem.state = NSOffState;
            break;
        }
        case 2: {
            _kitsuserviceitem.state = NSOffState;
            _anilistserviceitem.state = NSOffState;
            _malserviceitem.state = NSOnState;
            break;
        }
        default:
            [NSUserDefaults.standardUserDefaults setInteger:0 forKey:@"currentservice"];
            _kitsuserviceitem.state = NSOnState;
            _anilistserviceitem.state = NSOffState;
            break;
        }
}

- (IBAction)setService:(id)sender {
    AppDelegate *del = (AppDelegate *)NSApplication.sharedApplication.delegate;
    if (del.scrobbling) {
        [del showNotification:@"Can't Change Service" message:@"Please disable Auto Scrobble before changing services" withIdentifier:@"servicechangefailed"];
        return;
    }
    NSMenuItem *selectedmenuitem = (NSMenuItem *)sender;
    int previousservice = (int)[NSUserDefaults.standardUserDefaults integerForKey:@"currentservice"];
    int tag = (int)selectedmenuitem.tag;
    if (previousservice == tag) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setInteger:tag forKey:@"currentservice"];
    [self setmenuitemvaluefromdefaults];
    if (_actionblock) {
        _actionblock(tag, previousservice);
    }
}

- (void)setServiceWithServiceId:(int)serviceid {
    int previousservice = (int)[NSUserDefaults.standardUserDefaults integerForKey:@"currentservice"];
    if (previousservice == serviceid) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setInteger:serviceid forKey:@"currentservice"];
    [self setmenuitemvaluefromdefaults];
    if (_actionblock) {
        _actionblock(serviceid, previousservice);
    }
}

- (void)enableservicemenuitems:(bool)enable {
    _kitsuserviceitem.enabled = enable;
    _anilistserviceitem.enabled = enable;
}

@end
