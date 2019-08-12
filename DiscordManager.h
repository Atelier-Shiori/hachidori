//
//  DiscordManager.h
//  Hachidori
//
//  Created by 小鳥遊六花 on 1/31/18.
//

#import <Foundation/Foundation.h>

@interface DiscordManager : NSObject
@property (getter=getStarted) bool discordrpcrunning;
@property bool discordsdkinitalized;

- (void)startDiscordRPC;
- (void)shutdownDiscordRPC;
- (void)UpdatePresence:(NSString *)state withDetails:(NSString *)details isStreaming:(bool)isStreaming;
- (void)removePresence;
@end
