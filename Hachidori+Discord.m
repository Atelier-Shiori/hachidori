//
//  Hachidori+Discord.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/30.
//

#import "Hachidori+Discord.h"

@implementation Hachidori (Discord)
- (void)sendDiscordPresence {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"usediscordrichpresence"] && self.discordmanager.discordrpcrunning) {
        [self.discordmanager UpdatePresence:[NSString stringWithFormat:@"%@ Episode %@ ", self.WatchStatus,self.LastScrobbledEpisode] withDetails:[NSString stringWithFormat:@"%@",  self.LastScrobbledActualTitle ]];
    }
}
@end
