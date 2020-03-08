//
//  DiscordManager.m
//  Hachidori
//
//  Created by 小鳥遊六花 on 1/31/18.
//

#import "DiscordManager.h"
#include "discord_game_sdk.h"
#import <MSWeakTimer_macOS/MSWeakTimer.h>

#define DISCORD_REQUIRE(x) assert(x == DiscordResult_Ok)

static const long APPLICATION_ID = 451384588405571585;
struct Application {
    struct IDiscordCore* core;
    struct IDiscordActivityManager* activities;
    struct IDiscordUsers* users;
};

struct Application app;

@interface DiscordManager ()
@property (strong, nonatomic) dispatch_queue_t callbackQueue;
@property (strong) MSWeakTimer *timer;
@end

@implementation DiscordManager

- (instancetype)init {
    if (self = [super init]) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recieveNotification:) name:@"DiscordStateChanged" object:nil];
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"usediscordrichpresence"]) {
            [self startDiscordRPC];
        }
        _callbackQueue =  dispatch_queue_create( "moe.malupdaterosx.hachidori.callbackQueue", NULL );
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)recieveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"DiscordStateChanged"]) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"usediscordrichpresence"]) {
            [self startDiscordRPC];
        }
        else {
            [self removePresence];
            [self shutdownDiscordRPC];
        }
    }
}

void InitDiscord()
{
    // Don't forget to memset or otherwise initialize your classes!
    memset(&app, 0, sizeof(app));
    
    IDiscordCoreEvents events;
    memset(&events, 0, sizeof(events));
    
    struct IDiscordActivityEvents activities_events;
    memset(&activities_events, 0, sizeof(activities_events));
    
    struct DiscordCreateParams params;
    params.client_id = APPLICATION_ID;
    params.flags = DiscordCreateFlags_Default;
    params.events = &events;
    params.activity_events = &activities_events;
    params.event_data = &app;
    DiscordCreate(DISCORD_VERSION, &params, &app.core);
    
    app.activities = app.core->get_activity_manager(app.core);
}

void UpdateActivityCallback(void* data, enum EDiscordResult result)
{
    @try {
        DISCORD_REQUIRE(result);
    }
    @catch (NSException *ex) {
    }
}

- (void)startDiscordRPC {
    NSLog(@"Discord Rich Presence enabled");
    if ([self checkDiscordRunning]) {
        if (!_discordsdkinitalized) {
            InitDiscord();
        }
        [self startCallback];
    }
    _discordrpcrunning = true;
}

- (void)shutdownDiscordRPC {
    NSLog(@"Discord Rich Presence disabled");
    [self stopCallback];
    [self removePresence];
    _discordrpcrunning = false;
}

- (void)UpdatePresence:(NSString *)state withDetails:(NSString *)details isStreaming:(bool)isStreaming {
    if ([self checkDiscordRunning]) {
        if (!_discordsdkinitalized) {
            InitDiscord();
            _discordsdkinitalized = true;
        }
        @try {
            app.activities->clear_activity(app.activities, 0, 0);
            struct DiscordActivity activity;
            strcpy(activity.state, state.UTF8String);
            strcpy(activity.details, details.UTF8String);
            activity.timestamps.start = [NSDate date].timeIntervalSince1970;
            activity.timestamps.end = [NSDate dateWithTimeIntervalSinceNow:86400].timeIntervalSince1970;
            strcpy(activity.assets.large_image, "default");
            strcpy(activity.assets.small_image, "default");
            strcpy(activity.assets.large_text, "");
            strcpy(activity.assets.small_text, "");
            activity.type = isStreaming ? DiscordActivityType_Streaming : DiscordActivityType_Watching;
            app.activities->update_activity(app.activities, &activity, 0, UpdateActivityCallback);
        } @catch (NSException *exception) {
        }
    }
}

- (void)removePresence {
    if ([self checkDiscordRunning] && _discordsdkinitalized) {
        @try {
            app.activities->clear_activity(app.activities, 0, 0);
        } @catch (NSException *exception) {
        }
    }
}

- (BOOL)checkDiscordRunning {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *runningApps = ws.runningApplications;
    NSRunningApplication *a;
    for (a in runningApps) {
        if ([a.bundleIdentifier localizedCaseInsensitiveContainsString:@"com.hnc.Discord"]) {
            return true;
        }
    }
    return false;
}

- (void)startCallback {
    _timer = [MSWeakTimer scheduledTimerWithTimeInterval:16
                                                  target:self
                                                selector:@selector(firetimer)
                                                userInfo:nil
                                                 repeats:YES
                                           dispatchQueue:_callbackQueue];
}

- (void)stopCallback {
    [_timer invalidate];
}

- (void)firetimer {
    if (_discordsdkinitalized && [self checkDiscordRunning]) {
        @try {
            DISCORD_REQUIRE(app.core->run_callbacks(app.core));
        }
        @catch(NSException *ex) {
        }
    }
}
@end
