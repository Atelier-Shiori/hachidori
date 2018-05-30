//
//  DiscordManager.m
//  Hachidori
//
//  Created by 小鳥遊六花 on 1/31/18.
//

#import "DiscordManager.h"
#import <DiscordRPC/DiscordRPC.h>

static const char* APPLICATION_ID = "451384588405571585";

@implementation DiscordManager

void InitDiscord()
{
    DiscordEventHandlers handlers;
    memset(&handlers, 0, sizeof(handlers));
    handlers.ready = handleDiscordReady;
    handlers.errored = handleDiscordError;
    handlers.disconnected = handleDiscordDisconnected;
    Discord_Initialize(APPLICATION_ID, &handlers, 1, NULL);
}
static void handleDiscordReady(void)
{
    printf("\nDiscord: ready\n");
}

static void handleDiscordDisconnected(int errcode, const char* message)
{
    printf("\nDiscord: disconnected (%d: %s)\n", errcode, message);
}

static void handleDiscordError(int errcode, const char* message)
{
    printf("\nDiscord: error (%d: %s)\n", errcode, message);
}

- (void)startDiscordRPC {
    InitDiscord();
    _discordrpcrunning = true;
}

- (void)shutdownDiscordRPC {
    Discord_Shutdown();
    _discordrpcrunning = false;
}

- (void)UpdatePresence:(NSString *)state withDetails:(NSString *)details {
    if ([self checkDiscordRunning]) {
        Discord_ClearPresence();
        DiscordRichPresence discordPresence;
        discordPresence.state = state.UTF8String;
        discordPresence.details = details.UTF8String;
        discordPresence.startTimestamp = 0;
        discordPresence.largeImageKey = "default";
        discordPresence.smallImageKey = "default";
        discordPresence.largeImageText = "";
        discordPresence.smallImageText = "";
        discordPresence.partyId = NULL;
        discordPresence.joinSecret = NULL;
        discordPresence.spectateSecret = NULL;
        discordPresence.matchSecret = NULL;
        discordPresence.spectateSecret = NULL;
        Discord_UpdatePresence(&discordPresence);
        Discord_RunCallbacks();
    }
}

- (void)removePresence {
    if ([self checkDiscordRunning]) {
        Discord_ClearPresence();
        Discord_RunCallbacks();
    }
}

- (BOOL)checkDiscordRunning {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *runningApps = ws.runningApplications;
    NSRunningApplication *a;
    for (a in runningApps) {
        if ([a.bundleIdentifier isEqualToString:@"com.hnc.Discord"]) {
            return true;
        }
    }
    return false;
}
@end
