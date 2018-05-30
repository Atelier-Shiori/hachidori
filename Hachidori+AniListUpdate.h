//
//  Hachidori+AniListUpdate.h
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/28.
//

#import "Hachidori.h"

@interface Hachidori (AniListUpdate)
- (int)anilistperformupdate:(NSString *)titleid;
- (void)anilistupdatestatus:(NSString *)titleid
                  episode:(NSString *)episode
                    score:(int)showscore
              watchstatus:(NSString*)showwatchstatus
                    notes:(NSString*)note
                isPrivate:(BOOL)privatevalue
               completion:(void (^)(bool success))completionhandler;
- (BOOL)aniliststopRewatching:(NSString *)titleid;
- (bool)anilistremovetitle:(NSString *)titleid;
- (void)aniliststoreLastScrobbled;
@end
