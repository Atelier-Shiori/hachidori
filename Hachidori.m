//
//  Hachidori.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import <DetectionKit/DetectionKit.h>
#import "Hachidori+Keychain.h"
#import "Hachidori+Search.h"
#import "Hachidori+Update.h"
#import "Hachidori+UserStatus.h"
#import "ClientConstants.h"
#import "AppDelegate.h"
#import <Reachability/Reachability.h>


@implementation Hachidori
@synthesize managedObjectContext;
@synthesize online;
- (instancetype)init{
    _confirmed = true;
    //Create Reachability Object
    _reach = [Reachability reachabilityWithHostname:@"kitsu.io"];
    // Set up blocks
    // Set the blocks
    _reach.reachableBlock = ^(Reachability*reach)
    {
        online = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Kitsu is reachable.");
        });
    };
    _reach.unreachableBlock = ^(Reachability*reach)
    {
        online = false;
        NSLog(@"Computer not connected to internet or Kitsu is down");
    };
    // Start notifier
    [_reach startNotifier];
    //Set up Kodi Reachability
    _detection = [Detection new];
    [_detection setKodiReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]];
    [_detection setPlexReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enableplexapi"]];
    return [super init];
}
/* 
 
 Accessors
 
 */
- (int)getWatchStatus
{
    if ([_WatchStatus isEqualToString:@"currently-watching"]) {
		return 0;
    }
    else if ([_WatchStatus isEqualToString:@"completed"]) {
		return 1;
    }
    else if ([_WatchStatus isEqualToString:@"on-hold"]) {
		return 2;
    }
    else if ([_WatchStatus isEqualToString:@"dropped"]) {
		return 3;
    }
    else if ([_WatchStatus isEqualToString:@"plan-to-watch"]) {
        return 4;
    }
    else {
		return 0; //fallback
    }
}
- (int)getQueueCount{
    __block int count = 0;
    NSManagedObjectContext * moc = self.managedObjectContext;
    [moc performBlockAndWait:^{
        NSError * error;
        NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND (status == %i)", false, 23];
        NSFetchRequest * queuefetch = [[NSFetchRequest alloc] init];
        queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
        queuefetch.predicate = predicate;
        NSArray * queue = [moc executeFetchRequest:queuefetch error:&error];
        count = (int)queue.count;
    }];
    return count;
}
- (AFOAuthCredential *)getFirstAccount{
   return [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori"];
}
- (NSString *)getUserid{
    NSString * userid = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserID"];
    if (userid) {
        return userid;
    }
    return nil;
}
/*
 
 Update Methods
 
 */

- (int)startscrobbling {
    int detectstatus = [self detectmedia];
	if (detectstatus == ScrobblerDetectedMedia) { // Detects Title
        if (online) {
            return [self scrobble];
            // Empty out Detected Title/Episode to prevent same title detection
            _DetectedTitle = nil;
            _DetectedEpisode = nil;
            _DetectedSource = nil;
            _DetectedGroup = nil;
            _DetectedType = nil;
            _DetectedSeason = 0;
            // Reset correcting Value
            _correcting = false;
        }
        else {
            __block NSError * error;
            if (![self checkifexistinqueue]) {
                // Store in offline queue
                    [managedObjectContext performBlockAndWait:^{
                    NSManagedObject *obj = [NSEntityDescription
                                            insertNewObjectForEntityForName:@"OfflineQueue"
                                            inManagedObjectContext: managedObjectContext];
                    // Set values in the new record
                    [obj setValue:_DetectedTitle forKey:@"detectedtitle"];
                    [obj setValue:_DetectedEpisode forKey:@"detectedepisode"];
                    [obj setValue:_DetectedType forKey:@"detectedtype"];
                    [obj setValue:_DetectedSource forKey:@"source"];
                    [obj setValue:@(_DetectedSeason) forKey:@"detectedseason"];
                    [obj setValue:@(_DetectedTitleisMovie) forKey:@"ismovie"];
                    [obj setValue:@(_DetectedTitleisEpisodeZero) forKey:@"iszeroepisode"];
                    [obj setValue:@23 forKey:@"status"];
                    [obj setValue:[NSNumber numberWithBool:false] forKey:@"scrobbled"];
                    //Save
                    [managedObjectContext save:&error];
                }];
            }
            // Store Last Scrobbled Title
            _LastScrobbledTitle = _DetectedTitle;
            _LastScrobbledEpisode = _DetectedEpisode;
            _DetectedCurrentEpisode = _DetectedEpisode.intValue;
            _LastScrobbledSource = _DetectedSource;
            _LastScrobbledActualTitle = _DetectedTitle;
            _confirmed = true;
            // Reset Detected Info
            _DetectedTitle = nil;
            _DetectedEpisode = nil;
            _DetectedSource = nil;
            _DetectedGroup = nil;
            _DetectedType = nil;
            _DetectedSeason = 0;
            _Success = true;
            return ScrobblerOfflineQueued;
        }
	}
    return detectstatus;
}
- (NSDictionary *)scrobblefromqueue{
    // Restore Detected Media
    __block NSError * error;
    NSManagedObjectContext * moc = self.managedObjectContext;
    __block NSArray * queue;
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND ((status == %i) OR (status == %i))", false, 23, 3];
    NSFetchRequest * queuefetch = [[NSFetchRequest alloc] init];
    queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
    queuefetch.predicate = predicate;
    [moc performBlockAndWait:^{
        queue = [moc executeFetchRequest:queuefetch error:&error];
    }];
    int successc = 0;
    int fail = 0;
    bool confirmneeded = false;
    if (queue.count > 0) {
        for (NSManagedObject * item in queue) {
            // Restore detected title and episode from coredata
            _DetectedTitle = [item valueForKey:@"detectedtitle"];
            _DetectedEpisode = [item valueForKey:@"detectedepisode"];
            _DetectedSource = [item valueForKey:@"source"];
            _DetectedType = [item valueForKey:@"detectedtype"];
            _DetectedSeason = [[item valueForKey:@"detectedseason"] intValue];
            _DetectedTitleisMovie = [[item valueForKey:@"ismovie"] boolValue];
            _DetectedTitleisEpisodeZero = [[item valueForKey:@"iszeroepisode"] boolValue];
            int result = [self scrobble];
            bool scrobbled;
            NSManagedObject * record = [self checkifexistinqueue];
            // Record Results
            [record setValue:@(result) forKey:@"status"];
            // 0 - nothing playing; 1 - same episode playing; 2 - No Update Needed; 3 - Confirm title before updating  21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed - 23 - Offline Queue;
            switch (result) {
                case ScrobblerTitleNotFound:
                case ScrobblerAddTitleFailed:
                case ScrobblerUpdateFailed:
                case ScrobblerFailed:
                    fail++;
                    scrobbled = false;
                    break;
                case ScrobblerConfirmNeeded:
                    successc++;
                    scrobbled = true;
                    break;
                default:
                    successc++;
                    scrobbled = true;
                    break;
            }
            [record setValue:@(scrobbled) forKey:@"scrobbled"];
            [moc performBlockAndWait:^{
                [moc save:&error];
            }];
            
            //Save
            if (result == ScrobblerConfirmNeeded) {
                confirmneeded = true;
                break;
            }
        }
    }
    if (successc > 0) {
        _Success = true;
    }
    return @{@"success": @(successc), @"fail": @(fail), @"confirmneeded" : @(confirmneeded)};
}
- (int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)correctonce{
    _correcting = true;
    NSString * lasttitle;
    if (correctonce) {
        lasttitle = _LastScrobbledTitle;
    }
    _DetectedTitle = showtitle;
    _DetectedEpisode = episode;
    if (!_FailedSource) {
        _DetectedSource = _LastScrobbledSource;
    }
    else {
        _DetectedSource = _FailedSource;
    }
    // Check Exceptions
    [self checkExceptions];
    // Scrobble and return status code
    int status = [self scrobble];
    if (correctonce) {
        _LastScrobbledTitle = lasttitle; //Set the Last Scrobbled Title to exact title.
    }
    return status;
}

- (int)scrobble{
    int status;
	NSLog(@"=============");
	NSLog(@"Scrobbling...");
    NSLog(@"Getting AniID");
    // Regular Search
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        // Check Cache
        NSString *theid = [self checkCache];
        if (theid.length == 0)
            _AniID = [self searchanime]; // Not in cache, search
        else {
            _AniID = theid; // Set cached show id as AniID
            //If Detected Episode is missing, set it to 1 for sanity
            if (_DetectedEpisode.length == 0) {
                _DetectedEpisode = @"1";
            }
        }
    }
    else {
        _AniID = [self searchanime]; // Search Cache Disabled
    }
    if (_AniID.length > 0) {
        NSLog(@"Found %@", _AniID);
        // Nil out Failed Title and Episode
        _FailedTitle = nil;
        _FailedEpisode = nil;
        _FailedSource = nil;
        // Check Status and Update
        BOOL UpdateBool = [self checkstatus:_AniID];
        if (UpdateBool == 1) {
            if (_LastScrobbledTitleNew) {
                //Title is not on list. Add Title
                int s = [self updatetitle:_AniID];
                if (s == ScrobblerAddTitleSuccessful || s == ScrobblerConfirmNeeded) {
                    _Success = true;}
                else {
                    _Success = false;}
                status = s;
            }
            else {
                // Update Title as Usual
                int s = [self updatetitle:_AniID];
                if (s == ScrobblerUpdateNotNeeded || s == ScrobblerConfirmNeeded ||s == ScrobblerUpdateSuccessful ) {
                    _Success = true;
                }
                else {
                    _Success = false;}
                status = s;
            }
        }
        else {
            if (online) {
                 status = ScrobblerFailed;
            }
            else {
                status = ScrobblerFailed;
            }
        }
    }
    else {
        if (online) {
            // Not Successful
            NSLog(@"Error: Couldn't find title %@. Please add an Anime Exception rule.", _DetectedTitle);
            // Used for Exception Adding
            _FailedTitle = _DetectedTitle;
            _FailedEpisode = _DetectedEpisode;
            _FailedSource = _DetectedSource;
            status = ScrobblerTitleNotFound;
        }
        else {
            status = ScrobblerFailed;
        }
        
    }
    NSLog(@"Scrobble Complete with Status Code: %i", status);
    NSLog(@"=============");
    // Release Detected Title/Episode.
    return status;
}
- (NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type{
    //For unit testing only
    _DetectedTitle = title;
    _DetectedEpisode = episode;
    _DetectedSeason = season;
    _DetectedGroup = group;
    _DetectedType = type;
    _unittesting = true;
    //Check for zero episode as the detected episode
    [self checkzeroEpisode];
    //Check for Exceptions
    [self checkExceptions];
    //Retrieve Info
    NSDictionary * d = [self retrieveAnimeInfo:[self searchanime]];
    return d;
}
- (int)detectmedia {
    NSDictionary * result = [_detection detectmedia];
    return [self populatevalues:result];
}
- (int)populatevalues:(NSDictionary *) result{
    if (result !=nil) {
        //Populate Data
        _DetectedTitle = result[@"detectedtitle"];
        _DetectedEpisode = result[@"detectedepisode"];
        _DetectedSeason = ((NSNumber *)result[@"detectedseason"]).intValue;
        _DetectedGroup = result[@"group"];
        _DetectedSource = result[@"detectedsource"];
        if (((NSArray *)result[@"types"]).count > 0) {
            _DetectedType = (result[@"types"])[0];
        }
        else {
            _DetectedType = @"";
        }
        //Check for zero episode as the detected episode
        [self checkzeroEpisode];
        // Check if the title was previously scrobbled
        [self checkExceptions];
        if ([_DetectedTitle isEqualToString:_LastScrobbledTitle] && ([_DetectedEpisode isEqualToString: _LastScrobbledEpisode]||[self checkBlankDetectedEpisode]) && _Success == 1) {
            // Do Nothing
            return ScrobblerSameEpisodePlaying;
        }
        else {
            // Not Scrobbled Yet or Unsuccessful
            return ScrobblerDetectedMedia;
        }
    }
    else {
        return ScrobblerNothingPlaying;
    }

}
- (BOOL)checkBlankDetectedEpisode{
    return [_LastScrobbledEpisode isEqualToString:@"1"] && _DetectedEpisode.length == 0;
}
- (void)checkzeroEpisode{
    // For 00 Episodes
    if ([_DetectedEpisode isEqualToString:@"00"]||[_DetectedEpisode isEqualToString:@"0"]) {
        _DetectedEpisode = @"1";
        _DetectedTitleisEpisodeZero = true;
    }
    else if (([_DetectedType isLike:@"Movie"] || [_DetectedType isLike:@"OVA"] || [_DetectedType isLike:@"Special"]) && ([_DetectedEpisode isEqualToString:@"0"] || _DetectedEpisode.length == 0)) {
        _DetectedEpisode = @"1";
    }
    else {
        _DetectedTitleisEpisodeZero = false;
    }
}
- (BOOL)confirmupdate{
    _DetectedTitle = _LastScrobbledTitle;
    _DetectedEpisode = _LastScrobbledEpisode;
    _DetectedSource  = _LastScrobbledSource;
    NSLog(@"=============");
    NSLog(@"Confirming: %@ - %@",_LastScrobbledActualTitle, _LastScrobbledEpisode);
    int status = [self performupdate:_AniID];
    switch (status) {
        case ScrobblerAddTitleSuccessful:
        case ScrobblerUpdateSuccessful:
            // Clear Detected Episode and Title
            _DetectedTitle = nil;
            _DetectedEpisode = nil;
            _DetectedSource = nil;
            return true;
        default:
            return false;
    }
}
- (void)clearAnimeInfo{
    _LastScrobbledInfo = nil;
}
- (NSString *)checkCache{
    NSManagedObjectContext *moc = managedObjectContext;
    NSFetchRequest * allCaches = [[NSFetchRequest alloc] init];
    allCaches.entity = [NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", _DetectedTitle];
    allCaches.predicate = predicate;
    NSError * error = nil;
    NSArray * cache = [moc executeFetchRequest:allCaches error:&error];
    if (cache.count > 0) {
        for (NSManagedObject * cacheentry in cache) {
            NSString * title = [cacheentry valueForKey:@"detectedTitle"];
            if ([title isEqualToString:_DetectedTitle]) {
                NSLog(@"%@ found in cache!", title);
                // Total Episode check
                NSNumber * totalepisodes = [cacheentry valueForKey:@"totalEpisodes"];
                if (_DetectedEpisode.intValue <= totalepisodes.intValue || totalepisodes.intValue == 0 ) {
                    return [cacheentry valueForKey:@"id"];
                }
            }
        }
    }
    return @"";
}
- (void)checkExceptions{
    // Check Exceptions
    NSManagedObjectContext * moc = self.managedObjectContext;
	bool found = false;
	NSPredicate *predicate;
    for (int i = 0; i < 2; i++) {
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        __block NSError * error = nil;
        if (i == 0) {
            NSLog(@"Check Exceptions List");
            allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
			predicate = [NSPredicate predicateWithFormat: @"detectedTitle ==[c] %@", _DetectedTitle];
        }
        else if (i== 1 && [[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
                NSLog(@"Checking Auto Exceptions");
                allExceptions.entity = [NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc];
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND ((group == %@) OR (group == %@))", _DetectedTitle, _DetectedGroup, @"ALL"];
        }
        else {break;}
		// Set Predicate and filter exceiptions array
        allExceptions.predicate = predicate;
        __block NSArray * exceptions;
        [managedObjectContext performBlockAndWait:^{
        exceptions = [moc executeFetchRequest:allExceptions error:&error];
        }];
        if (exceptions.count > 0) {
            NSString * correcttitle;
            for (NSManagedObject * entry in exceptions) {
                NSLog(@"%@",(NSString *)[entry valueForKey:@"detectedTitle"]);
                if ([_DetectedTitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]]) {
                    correcttitle = (NSString *)[entry valueForKey:@"correctTitle"];
                    // Set Correct Title and Episode offset (if any)
                    int threshold = ((NSNumber *)[entry valueForKey:@"episodethreshold"]).intValue;
                    int offset = ((NSNumber *)[entry valueForKey:@"episodeOffset"]).intValue;
                    int tmpepisode = _DetectedEpisode.intValue - offset;
                    int mappedepisode;
					
					if (i==1) {
						mappedepisode = ((NSNumber *)[entry valueForKey:@"mappedepisode"]).intValue;
					}
					else {
                        mappedepisode = 0;
					}
					bool iszeroepisode;
					if (i==1) {
						iszeroepisode = ((NSNumber *)[entry valueForKey:@"iszeroepisode"]).boolValue;
					}
					else {
						iszeroepisode = false;
					}
                    
                    if (i==1 && _DetectedTitleisEpisodeZero == true && iszeroepisode == true) {
                        NSLog(@"%@ zero episode is found on exceptions list as %@.", _DetectedTitle, correcttitle);
                        _DetectedTitle = correcttitle;
                        _DetectedEpisode = [NSString stringWithFormat:@"%i", mappedepisode];
                        _DetectedTitleisEpisodeZero = true;
                        found = true;
                        break;
                    }
                    else if (i==1 && _DetectedTitleisEpisodeZero == false && iszeroepisode == true) {
                        continue;
                    }
                    if ((tmpepisode > threshold && threshold != 0) || (tmpepisode <= 0 && threshold != 1 && i==0)||(tmpepisode <= 0 && i==1)) {
                        continue;
                    }
                    else {
                        NSLog(@"%@ found on exceptions list as %@.", _DetectedTitle, correcttitle);
                        if (tmpepisode > 0) {
                            _DetectedEpisode = [NSString stringWithFormat:@"%i", tmpepisode];
                        }
                        _DetectedType = @"";
                        _DetectedTitle = correcttitle;
                        _DetectedSeason = 0;
                        _DetectedTitleisEpisodeZero = false;
                        found = true;
						break;
                    }
                }
            }
			if (found) {
                break;
            } //Break from exceptions check loop
        }
    }
}
- (NSManagedObject *)checkifexistinqueue{
    // Return existing offline queue item
    __block NSError * error;
    NSManagedObjectContext * moc = self.managedObjectContext;
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(detectedtitle ==[c] %@) AND (detectedepisode ==[c] %@) AND (detectedtype ==[c] %@) AND (ismovie == %i) AND (iszeroepisode == %i) AND (detectedseason == %i) AND (source == %@)", _DetectedTitle, _DetectedEpisode, _DetectedType, _DetectedTitleisMovie, _DetectedTitleisEpisodeZero, _DetectedSeason, _DetectedSource];
    NSFetchRequest * queuefetch = [[NSFetchRequest alloc] init];
    queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
    queuefetch.predicate = predicate;
    __block NSArray * queue;
    [moc performBlockAndWait:^{
        queue = [moc executeFetchRequest:queuefetch error:&error];
    }];
    if (queue.count > 0) {
        return (NSManagedObject *)queue[0];
    }
    return nil;
}
/*
 Token Refresh
 */
- (bool)checkexpired{
    AFOAuthCredential * cred = [self getFirstAccount];
    return cred.expired;
}
- (void)refreshtoken{
    AFOAuthCredential *cred =
    [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori"];
    NSURL *baseURL = [NSURL URLWithString:kBaseURL];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                                     clientID:kclient
                                                                       secret:ksecretkey];
    [OAuth2Manager setUseHTTPBasicAuthentication:NO];
    [OAuth2Manager authenticateUsingOAuthWithURLString:kTokenURL
                                            parameters:@{@"grant_type":@"refresh_token", @"refresh_token":cred.refreshToken} success:^(AFOAuthCredential *credential) {
        NSLog(@"Token refreshed");
        [AFOAuthCredential storeCredential:credential
                            withIdentifier:@"Hachidori"];
        AppDelegate * appdel = (AppDelegate *)[NSApplication sharedApplication].delegate;
        [appdel updatenow:self];
    }
                                               failure:^(NSError *error) {
                                                   NSLog(@"Token cannot be refreshed: %@", error);
                                               }];
   
}

- (void)resetinfo {
    // Resets Hachidori Engine when user logs out
    _LastScrobbledInfo = nil;
    _LastScrobbledTitle = nil;
    _LastScrobbledSource = nil;
    _LastScrobbledEpisode = nil;
    _LastScrobbledTitleNew = false;
    _LastScrobbledActualTitle = nil;
    _AniID = nil;
    _slug = nil;
}

@end
