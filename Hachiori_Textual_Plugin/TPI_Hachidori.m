//
//  TPI_Hachidori.m
//  Hachidori
//
//  Created by 天々座理世 on 2017/04/16.
//  Copyright 2009-2017 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "TPI_Hachidori.h"

@implementation TPI_Hachidori
- (void)pluginLoadedIntoMemory {

}
- (NSArray *)subscribedUserInputCommands
{
    return @[@"hachidori",@"hachidorinolink"];
}
- (void)userInputCommandInvokedOnClient:(IRCClient *)client
                          commandString:(NSString *)commandString
                          messageString:(NSString *)messageString {
    IRCChannel *channel = mainWindow().selectedChannel;
    
    NSString *message;
    if (channel == nil) {
        return;
    }
    if ([commandString isEqualToString:@"HACHIDORI"]) {
        message = [self generateMessage:true withClient:client];
        if (message) {
            [self sendMessage:message onClient:client toChannel:channel];
        }
    }
    else if ([commandString isEqualToString:@"HACHIDORINOLINK"]) {
        message = [self generateMessage:false withClient:client];
        if (message) {
            [self sendMessage:message onClient:client toChannel:channel];
        }
    }
    else {
        return;
    }
}
- (void)printDebugInformation:(NSString *)message onClient:(IRCClient *)client inChannel:(IRCChannel *)channel {
    NSArray *messages = [message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *messageSplit in messages) {
        [client printDebugInformation:messageSplit inChannel:channel];
    }
}

- (NSString *)generateMessage:(BOOL)sharelink withClient:(IRCClient *)client {
    IRCChannel *channel = mainWindow().selectedChannel;
    if ([self checkIdentifier:@"moe.ateliershiori.Hachidori"]) {
        NSString *json;
        @try {
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/usr/bin/osascript"];
            NSString *arguments = [NSString stringWithFormat:@"-e %@", @"tell application \"Hachidori\" to getstatus"];
            [task setArguments:[NSArray arrayWithObjects:arguments, nil]];
            NSPipe *pipe;
            pipe = [NSPipe pipe];
            task.standardOutput = pipe;
            
            NSFileHandle *file;
            file = pipe.fileHandleForReading;
            
            [task launch];
            [task waitUntilExit];
            NSData *data;
            data = [file readDataToEndOfFile];
            
            json = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        } @catch (NSException *e) {
            [self printDebugInformation:@"Could not output message" onClient:client inChannel:channel];
        }
        if (json.length > 0) {
            NSError *jerror;
            NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *nowplaying = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jerror];
            NSString * message;
            if (sharelink) {
                message = [NSString stringWithFormat:@"(Hachidori) Watching %@ Episode %@ from %@ - https://kitsu.io/anime/%@", nowplaying[@"scrobbledactualtitle"], nowplaying[@"scrobbledEpisode"], nowplaying[@"source"], nowplaying[@"id"]];
            }
            else {
                message = [NSString stringWithFormat:@"(Hachidori) Watching %@ Episode %@ from %@", nowplaying[@"scrobbledactualtitle"], nowplaying[@"scrobbledEpisode"], nowplaying[@"source"]];
            }
            return message;
        }
    }
    return nil;

}

- (BOOL)checkIdentifier:(NSString*)identifier {
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    NSArray *runningApps = [ws runningApplications];
    NSRunningApplication *a;
    for (a in runningApps) {
        if ([[a bundleIdentifier] isEqualToString:identifier]) {
            return true;
        }
    }
    return false;
}

- (void)sendMessage:(NSString *)message onClient:(IRCClient *)client toChannel:(IRCChannel *)channel
{
    NSArray *messages = [message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *messageSplit in messages) {
        [client sendPrivmsg:messageSplit toChannel:channel];
    }
}

@end
