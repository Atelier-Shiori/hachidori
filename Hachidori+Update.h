//
//  Hachidori+Update.h
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"

@interface Hachidori (Update)
- (int)updatetitle:(NSString *)titleid;
- (int)performupdate:(NSString *)titleid;
- (void)updatestatus:(NSString *)titleid
             episode:(NSString *)episode
               score:(int)showscore
         watchstatus:(NSString*)showwatchstatus
               notes:(NSString*)note
           isPrivate:(BOOL)privatevalue
          completion:(void (^)(bool success))completionhandler;
- (BOOL)stopRewatching:(NSString *)titleid;
- (bool)removetitle:(NSString *)titleid;
@end
