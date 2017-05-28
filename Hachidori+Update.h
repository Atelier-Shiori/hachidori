//
//  Hachidori+Update.h
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"

@interface Hachidori (Update)
- (int)updatetitle:(NSString *)titleid;
- (int)performupdate:(NSString *)titleid;
- (BOOL)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(float)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue;
- (BOOL)stopRewatching:(NSString *)titleid;
- (bool)removetitle:(NSString *)titleid;
@end
