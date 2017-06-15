//
//  ShareMenu.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/06/15.
//  Copyright 2009-2017 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>

@interface ShareMenu : NSObject
@property (strong) IBOutlet NSMenu *shareMenu;
@property (strong) NSArray *shareItems;
- (void)generateShareMenu:(NSArray *)shareItems;
- (IBAction)shareFromService:(id)sender;
- (void)resetShareMenu;
@end
