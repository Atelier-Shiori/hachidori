//
//  Hachidori+UserStatus.h
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"

@interface Hachidori (UserStatus)
- (BOOL)checkstatus:(NSString *)titleid withService:(int)service;
- (NSDictionary *)retrieveAnimeInfo:(NSString *)slug withService:(int)service;
- (void)populateStatusData:(NSDictionary *)d titleid:(NSString *)aid withDetectedScrobble:(DetectedScrobbleStatus *)dscrobble withService:(int)service;
@end
