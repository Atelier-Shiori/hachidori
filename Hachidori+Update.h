//
//  Hachidori+Update.h
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import "Hachidori+MultiScrobble.h"

@interface Hachidori (Update)
- (int)updatetitle:(NSString *)titleid;
- (int)performupdate:(NSString *)titleid withService:(long)service;
- (void)updatestatus:(NSString *)titleid
             episode:(NSString *)episode
               score:(int)showscore
         watchstatus:(NSString*)showwatchstatus
               notes:(NSString*)note
           isPrivate:(BOOL)privatevalue
          completion:(void (^)(bool success))completionhandler
         withService:(long)service;
- (BOOL)stopRewatching:(NSString *)titleid withService:(long)service;
- (bool)removetitle:(NSString *)titleid withService:(long)service;
@end
