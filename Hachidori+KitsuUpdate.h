//
//  Hachidori+KitsuUpdate.h
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/28.
//

#import "Hachidori.h"

@interface Hachidori (KitsuUpdate)
- (int)kitsuperformupdate:(NSString *)titleid;
- (void)kitsuupdatestatus:(NSString *)titleid
             episode:(NSString *)episode
               score:(int)showscore
         watchstatus:(NSString*)showwatchstatus
               notes:(NSString*)note
           isPrivate:(BOOL)privatevalue
          completion:(void (^)(bool success))completionhandler;
- (BOOL)kitsustopRewatching:(NSString *)titleid;
- (bool)kitsuremovetitle:(NSString *)titleid;
- (void)kitsustoreLastScrobbled;

@end
