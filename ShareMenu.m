//
//  ShareMenu.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/06/15.
//  Copyright 2009-2017 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "ShareMenu.h"

@implementation ShareMenu
- (void)generateShareMenu:(NSArray *)items {
    //Clear Share Menu
    [_shareMenu removeAllItems];
    // Workaround for Share Toolbar Item
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    shareIcon.image = [NSImage imageNamed:NSImageNameShareTemplate];
    [shareIcon setHidden:YES];
    shareIcon.title = @"";
    [_shareMenu addItem:shareIcon];
    //Generate Items to Share
    _shareItems = items;
    //Get Share Services for Items
    NSArray *shareServiceforItems = [NSSharingService sharingServicesForItems:_shareItems];
    //Generate Share Items and populate Share Menu
    for (NSSharingService *cservice in shareServiceforItems) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:cservice.title action:@selector(shareFromService:) keyEquivalent:@""];
        item.representedObject = cservice;
        item.image = cservice.image;
        item.target = self;
        [_shareMenu addItem:item];
    }
}
- (IBAction)shareFromService:(id)sender {
    // Share Item
    [[sender representedObject] performWithItems:_shareItems];
}
- (void)resetShareMenu {
    // Workaround for Share Toolbar Item
    [_shareMenu removeAllItems];
    NSMenuItem *shareIcon = [[NSMenuItem alloc] init];
    shareIcon.image = [NSImage imageNamed:NSImageNameShareTemplate];
    [shareIcon setHidden:YES];
    shareIcon.title = @"";
    [_shareMenu addItem:shareIcon];
}
@end
