//
//  Hachidori.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import "Hachidori+AnimeRelations.h"
#import "Hachidori+userinfo.h"
#import "AniListConstants.h"
#import <DetectionKit/DetectionKit.h>
#import <AFNetworking/AFNetworking.h>
#import <TwitterManagerKit/TwitterManagerKit.h>
#import "Hachidori+Search.h"
#import "Hachidori+Update.h"
#import "Hachidori+UserStatus.h"
#import "ClientConstants.h"
#import "AppDelegate.h"
#import <Reachability/Reachability.h>
#import "Utility.h"

@import AppCenterAnalytics;

@implementation Hachidori
@synthesize managedObjectContext;
@synthesize online;
- (instancetype)init {
    if (self = [super init]) {
        //_confirmed = true;
        //Reachability
        [self setNotifier];
        //Set up Kodi Reachability
        _detection = [Detection new];
        [_detection setKodiReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]];
        [_detection setPlexReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enableplexapi"]];
        // Init Twitter Manager
        _twittermanager = [HachidoriTwitterManager new];
        // Init Discord
        self.discordmanager = [DiscordManager new];
        // Init AFNetworking
        _syncmanager = [AFHTTPSessionManager manager];
        _syncmanager.requestSerializer = [AFJSONRequestSerializer serializer];
        _syncmanager.responseSerializer = [AFJSONResponseSerializer serializer];
        _syncmanager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"application/vnd.api+json", @"text/javascript", @"text/html", @"text/plain", nil];
        [_syncmanager.requestSerializer setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Content-Type"];
        _syncmanager.completionQueue = dispatch_queue_create("AFNetworking+Synchronous", NULL);
        _asyncmanager = [AFHTTPSessionManager manager];
        _asyncmanager.requestSerializer = [AFJSONRequestSerializer serializer];
        _asyncmanager.responseSerializer = [AFJSONResponseSerializer serializer];
        _asyncmanager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"application/vnd.api+json", @"text/javascript", @"text/html", @"text/plain", nil];
        [_asyncmanager.requestSerializer setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Content-Type"];
        // Setup Update Managers
        _anilistmanager = [AniListUpdateManager new];
        _anilistmanager.syncmanager = _syncmanager;
        _anilistmanager.asyncmanager = _asyncmanager;
        _kitsumanager = [KitsuUpdateManager new];
        _kitsumanager.syncmanager = _syncmanager;
        _kitsumanager.asyncmanager = _asyncmanager;
        // Set Observers
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"PlexToggled" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"PlexAddressChanged" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"KodiToggled" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"KodiAddressChanged" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveNotification:) name:@"AccountLoggedOut" object:nil];
        //[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveSocialNotification:) name:@"TwitterAddTweet" object:nil];
        //[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveSocialNotification:) name:@"TwitterUpdateTweet" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveSocialNotification:) name:@"TwitterUpdateStatusTweet" object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveSocialNotification:) name:@"UpdateDiscordStatus" object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"PlexToggled"]) {
        [_detection setPlexReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enableplexapi"]];
    }
    else if ([notification.name isEqualToString:@"PlexAddressChanged"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableplexapi"]) {
            NSString *newaddress = (NSString *)notification.object;
            [_detection setPlexReachAddress:newaddress];
        }
    }
    else if ([notification.name isEqualToString:@"KodiToggled"]) {
        [_detection setKodiReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]];
    }
    else if ([notification.name isEqualToString:@"KodiAddressChanged"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]) {
            NSString *newaddress = (NSString *)notification.object;
            [_detection setKodiReachAddress:newaddress];
        }
    }
    else if ([notification.name isEqualToString:@"AccountLoggedOut"]) {
        NSNumber *loggedoutservice = notification.object;
        [self resetInfoWithService:loggedoutservice.intValue];
    }
}

- (void)receiveSocialNotification:(NSNotification *)notification {
    LastScrobbleStatus *lscrobbled = notification.object;
    if (lscrobbled) {
        if ([notification.name isEqualToString:@"TwitterAddTweet"]) {
            [_twittermanager postaddanimetweet:lscrobbled];
        }
        else if ([notification.name isEqualToString:@"TwitterUpdateTweet"]) {
            [_twittermanager postupdateanimetweet:lscrobbled];
        }
        else if ([notification.name isEqualToString:@"TwitterUpdateStatusTweet"]) {
            [_twittermanager postupdatestatustweet:lscrobbled];
        }
        else if ([notification.name isEqualToString:@"UpdateDiscordStatus"]) {
            [self sendDiscordPresence:lscrobbled];
        }
    }
}

- (int)getQueueCount {
    __block int count = 0;
    NSManagedObjectContext * moc = self.managedObjectContext;
    [moc performBlockAndWait:^{
        NSError * error;
        NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND (status == %i) AND (service == %li)", false, 23, [Hachidori currentService]];
        NSFetchRequest * queuefetch = [[NSFetchRequest alloc] init];
        queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
        queuefetch.predicate = predicate;
        NSArray * queue = [moc executeFetchRequest:queuefetch error:&error];
        count = (int)queue.count;
    }];
    return count;
}

+ (long)currentService {
    return [NSUserDefaults.standardUserDefaults integerForKey:@"currentservice"];
}

+ (NSString *)currentServiceName {
    return [Hachidori serviceNameWithServiceID:[Hachidori currentService]];
}

+ (NSString *)serviceNameWithServiceID:(int)service {
    switch (service) {
        case 0:
            return @"Kitsu";
        case 1:
            return @"AniList";
        default:
            break;
    }
    return @"";
}

+ (AFOAuthCredential *)getCurrentFirstAccount {
    return [self getFirstAccount:[Hachidori currentService]];
}
    
+ (AFOAuthCredential *)getFirstAccount: (long)service {
    switch (service) {
        case 0:
            return [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori"];
        case 1:
            return [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori - AniList"];
        default:
            return nil;
    }
}
+ (NSString *)getUserid:(int)service {
    NSString * userid;
    switch (service) {
        case 0: {
            userid = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserID"];
            if (userid) {
                return userid;
            }
        }
        case 1: {
            userid = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserID-anilist"];
            if (userid) {
                return userid;
            }
        }
        default: {
            break;
        }
    }
    return nil;
}

- (int)startscrobbling {
    int detectstatus = [self detectmedia];
	if (detectstatus == ScrobblerDetectedMedia) { // Detects Title
        if (online) {
            int result = [self scrobble];
            // Empty out Detected Title/Episode to prevent same title detection
            //_DetectedTitle = nil;
            //_DetectedEpisode = nil;
            //_DetectedSource = nil;
            //_DetectedGroup = nil;
            //_DetectedType = nil;
            //_DetectedSeason = 0;
            if (_lastscrobble.confirmed) {
                [self clearDetectedScrobbled];
            }
            // Reset correcting Value
            _correcting = false;
            return result;
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
                    [obj setValue:_detectedscrobble.DetectedTitle forKey:@"detectedtitle"];
                    [obj setValue:_detectedscrobble.DetectedEpisode forKey:@"detectedepisode"];
                    [obj setValue:_detectedscrobble.DetectedType forKey:@"detectedtype"];
                    [obj setValue:_detectedscrobble.DetectedSource forKey:@"source"];
                    [obj setValue:@(_detectedscrobble.DetectedSeason) forKey:@"detectedseason"];
                    [obj setValue:@(_detectedscrobble.DetectedTitleisMovie) forKey:@"ismovie"];
                    [obj setValue:@(_detectedscrobble.DetectedTitleisEpisodeZero) forKey:@"iszeroepisode"];
                    [obj setValue:@23 forKey:@"status"];
                    [obj setValue:@NO forKey:@"scrobbled"];
                    [obj setValue:@([Hachidori currentService]) forKey:@"service"];
                    //Save
                    [managedObjectContext save:&error];
                }];
            }
            // Store Last Scrobbled Title
            _lastscrobble = [LastScrobbleStatus new];
            [_lastscrobble transferDetectedScrobble:_detectedscrobble];
            //_LastScrobbledTitle = _DetectedTitle;
            //_LastScrobbledEpisode = _DetectedEpisode;
            //_DetectedCurrentEpisode = _DetectedEpisode.intValue;
            //_LastScrobbledSource = _DetectedSource;
            //_LastScrobbledActualTitle = _DetectedTitle;
            _lastscrobble.confirmed = true;
            // Reset Detected Info
            [self clearDetectedScrobbled];
            //_DetectedTitle = nil;
            //_DetectedEpisode = nil;
            //_DetectedSource = nil;
            //_DetectedGroup = nil;
            //_DetectedType = nil;
            //_DetectedSeason = 0;
            
            _Success = true;
            return ScrobblerOfflineQueued;
        }
	}
    return detectstatus;
}
- (NSDictionary *)scrobblefromqueue {
    // Restore Detected Media
    __block NSError * error;
    NSManagedObjectContext * moc = self.managedObjectContext;
    __block NSArray * queue;
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND (service == %li) AND ((status == %i) OR (status == %i))", false, [Hachidori currentService], 23, 3];
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
            [self setDetectScrobble:[DetectedScrobbleStatus new]];
            _detectedscrobble.DetectedTitle = [item valueForKey:@"detectedtitle"];
            _detectedscrobble.DetectedEpisode = [item valueForKey:@"detectedepisode"];
            _detectedscrobble.DetectedSource = [item valueForKey:@"source"];
            _detectedscrobble.DetectedType = [item valueForKey:@"detectedtype"];
            _detectedscrobble.DetectedSeason = [[item valueForKey:@"detectedseason"] intValue];
            _detectedscrobble.DetectedTitleisMovie = [[item valueForKey:@"ismovie"] boolValue];
            _detectedscrobble.DetectedTitleisEpisodeZero = [[item valueForKey:@"iszeroepisode"] boolValue];
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
    if (!_detectedscrobble.FailedSource) {
        [self setDetectScrobble:[DetectedScrobbleStatus new]];
    }
    NSString * lasttitle;
    if (correctonce) {
        lasttitle = _lastscrobble.LastScrobbledTitle;
    }
    
    _detectedscrobble.DetectedTitle = showtitle;
    _detectedscrobble.DetectedEpisode = episode;
    _detectedscrobble.DetectedSeason = !_detectedscrobble.FailedSource ? _detectedscrobble.FailedSeason : _lastscrobble.DetectedSeason;
    if (!_detectedscrobble.FailedSource) {
        _detectedscrobble.DetectedSource = _lastscrobble.LastScrobbledSource;
    }
    else {
        _detectedscrobble.DetectedSource = _detectedscrobble.FailedSource;
    }
    // Check Exceptions
    [self checkExceptions];
    // Scrobble and return status code
    int status = [self scrobble];
    if (correctonce) {
        //_LastScrobbledTitle = lasttitle; //Set the Last Scrobbled Title to exact title.
    }
    return status;
}

- (int)scrobble {
    [MSAnalytics trackEvent:@"Starting Scrobble."];
    int status;
	NSLog(@"=============");
	NSLog(@"Scrobbling...");
    NSLog(@"Check Account Information");
    [self checkaccountinformation];
    NSLog(@"Getting AniID");
    // Regular Search
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        // Check Cache
        NSString *theid = [self checkCache];
        if (theid.length == 0)
            _detectedscrobble.AniID = [self searchanime]; // Not in cache, search
        else {
            _detectedscrobble.AniID = theid; // Set cached show id as AniID
            //If Detected Episode is missing, set it to 1 for sanity
            if (_detectedscrobble.DetectedEpisode.length == 0) {
                _detectedscrobble.DetectedEpisode = @"1";
            }
        }
    }
    else {
        _detectedscrobble.AniID = [self searchanime]; // Search Cache Disabled
    }
    if (_detectedscrobble.AniID.length > 0 && [self hasUserInfoCurrentService]) {
        NSLog(@"Found %@", _detectedscrobble.AniID);
        [MSAnalytics trackEvent:@"Found ID." withProperties:@{@"detectedTitle" : self.detectedscrobble.DetectedTitle, @"group" : self.detectedscrobble.DetectedGroup, @"season" : @(self.detectedscrobble.DetectedSeason).stringValue, @"source":self.detectedscrobble.DetectedSource, @"titleid" : self.detectedscrobble.AniID}];
        // Nil out Failed Title and Episode
        //_detectedscrobble.FailedTitle = nil;
        //_detectedscrobble.FailedEpisode = nil;
        //_detectedscrobble.FailedSource = nil;
        //_detectedscrobble.FailedSeason = 0;
        // Check Status and Update
        BOOL UpdateBool = [self checkstatus:_detectedscrobble.AniID withService:(int)[Hachidori currentService]];
        if (UpdateBool == 1) {
            if (_detectedscrobble.LastScrobbledTitleNew) {
                //Title is not on list. Add Title
                int s = [self updatetitle:_detectedscrobble.AniID];
                if (s == ScrobblerAddTitleSuccessful || s == ScrobblerConfirmNeeded) {
                    _Success = true;}
                else {
                    _Success = false;}
                status = s;
            }
            else {
                // Update Title as Usual
                int s = [self updatetitle:_detectedscrobble.AniID];
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
            NSLog(@"Error: Couldn't find title %@. Please add an Anime Exception rule.", _detectedscrobble.DetectedTitle);
            [MSAnalytics trackEvent:@"Can't find title." withProperties:@{@"detectedTitle" : self.detectedscrobble.DetectedTitle, @"group" : self.detectedscrobble.DetectedGroup, @"season" : @(self.detectedscrobble.DetectedSeason).stringValue, @"source":self.detectedscrobble.DetectedSource}];
            // Used for Exception Adding
            _detectedscrobble.FailedTitle = _detectedscrobble.DetectedTitle;
            _detectedscrobble.FailedEpisode = _detectedscrobble.DetectedEpisode;
            _detectedscrobble.FailedSource = _detectedscrobble.DetectedSource;
            _detectedscrobble.FailedSeason = _detectedscrobble.DetectedSeason;
            status = ScrobblerTitleNotFound;
        }
        else {
            status = ScrobblerFailed;
        }
        
    }
    [MSAnalytics trackEvent:(status == ScrobblerNothingPlaying||status == ScrobblerSameEpisodePlaying||status == ScrobblerUpdateNotNeeded||status == ScrobblerConfirmNeeded||status == ScrobblerAddTitleSuccessful||status == ScrobblerUpdateSuccessful||status == ScrobblerOfflineQueued) ? @"Scrobble Successful" : @"Scrobble Failed" withProperties:_lastscrobble ? @{@"detectedTitle" : _lastscrobble.LastScrobbledTitle, @"actualtitle" : _lastscrobble.LastScrobbledActualTitle, @"season" : @(_lastscrobble.DetectedSeason).stringValue, @"source":_lastscrobble.LastScrobbledSource, @"episode" : _lastscrobble.LastScrobbledEpisode, @"result" : @(status).stringValue} : @{ @"status" : @(status).stringValue, @"detectedTitle" : _detectedscrobble.DetectedTitle, @"source" : _detectedscrobble.DetectedSource }];
    NSLog(@"Scrobble Complete with Status Code: %i", status);
    NSLog(@"=============");
    // Release Detected Title/Episode.
    return status;
}
- (NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type{
    //For unit testing only
    [self setDetectScrobble:[DetectedScrobbleStatus new]];
    _detectedscrobble.DetectedTitle = title;
    _detectedscrobble.DetectedEpisode = episode;
    _detectedscrobble.DetectedSeason = season;
    _detectedscrobble.DetectedGroup = group;
    _detectedscrobble.DetectedType = type;
    _unittesting = true;
    //Check for zero episode as the detected episode
    [self.detectedscrobble checkzeroEpisode];
    //Check for Exceptions
    [self checkExceptions];
    //Retrieve Info
    NSDictionary * d = [self retrieveAnimeInfo:[self searchanime] withService:(int)[Hachidori currentService]];
    return d;
}
- (int)detectmedia {
    NSDictionary * result = [_detection detectmedia];
    return [self populatevalues:result];
}
- (int)populatevalues:(NSDictionary *) result{
    if (result !=nil) {
        //Populate Data
        [self setDetectScrobble:[DetectedScrobbleStatus new]];
        _detectedscrobble.DetectedTitle = result[@"detectedtitle"];
        _detectedscrobble.DetectedEpisode = result[@"detectedepisode"];
        _detectedscrobble.DetectedSeason = ((NSNumber *)result[@"detectedseason"]).intValue;
        _detectedscrobble.DetectedGroup = result[@"group"];
        _detectedscrobble.DetectedSource = result[@"detectedsource"];
        if (((NSArray *)result[@"types"]).count > 0) {
            _detectedscrobble.DetectedType = (result[@"types"])[0];
        }
        else {
            _detectedscrobble.DetectedType = @"";
        }
        //Check for zero episode as the detected episode
        [self.detectedscrobble checkzeroEpisode];
        // Check if the title was previously scrobbled
        [self checkExceptions];
        if ([_detectedscrobble.DetectedTitle isEqualToString:_lastscrobble.LastScrobbledTitle] && ([_detectedscrobble.DetectedEpisode isEqualToString: _lastscrobble.LastScrobbledEpisode]||[self checkBlankDetectedEpisode]) && _Success == 1) {
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
    return [_lastscrobble.LastScrobbledEpisode isEqualToString:@"1"] && _detectedscrobble.DetectedEpisode.length == 0;
}
- (BOOL)confirmupdate {
    NSLog(@"=============");
    NSLog(@"Confirming: %@ - %@",_lastscrobble.LastScrobbledActualTitle, _lastscrobble.LastScrobbledEpisode);
    [MSAnalytics trackEvent:@"Confirming title." withProperties:@{@"detectedTitle" : _lastscrobble.LastScrobbledTitle, @"actualtitle" : _lastscrobble.LastScrobbledActualTitle, @"season" : @(_lastscrobble.DetectedSeason).stringValue, @"source":_lastscrobble.LastScrobbledSource, @"episode" : _lastscrobble.LastScrobbledEpisode}];
    int status = [self performupdate:_detectedscrobble.AniID withService:(int)[Hachidori currentService]];
    switch (status) {
        case ScrobblerAddTitleSuccessful:
        case ScrobblerUpdateSuccessful:
            // Clear Detected Episode and Title
            [self multiscrobbleWithType:self.correcting ? MultiScrobbleTypeCorrection : MultiScrobbleTypeScrobble withTitleID:_detectedscrobble.AniID];
            [self clearDetectedScrobbled];
            return true;
        default:
            return false;
    }
}
- (NSString *)checkCache {
    NSManagedObjectContext *moc = managedObjectContext;
    NSFetchRequest *allCaches = [[NSFetchRequest alloc] init];
    allCaches.entity = [NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@  AND service == %i", _detectedscrobble.DetectedTitle, [Hachidori currentService]];
    allCaches.predicate = predicate;
    NSError *error = nil;
    NSArray *cache = [moc executeFetchRequest:allCaches error:&error];
    if (cache.count > 0) {
        for (NSManagedObject *cacheentry in cache) {
            NSString *title = [cacheentry valueForKey:@"detectedTitle"];
            NSNumber *season = [cacheentry valueForKey:@"detectedSeason"];
            if ([title isEqualToString:_detectedscrobble.DetectedTitle] && _detectedscrobble.DetectedSeason == season.intValue) {
                NSLog(@"%@", season.intValue > 1 ? [NSString stringWithFormat:@"%@ Season %i is found in cache.", title, season.intValue] : [NSString stringWithFormat:@"%@ is found in cache.", title]);
                // Total Episode check
                NSNumber *totalepisodes = [cacheentry valueForKey:@"totalEpisodes"];
                if ( _detectedscrobble.DetectedEpisode.intValue <= totalepisodes.intValue || totalepisodes.intValue == 0 ) {
                    return [cacheentry valueForKey:@"id"];
                }
                else {
                    // Check Anime Relations
                    if ([NSUserDefaults.standardUserDefaults boolForKey:@"UseAnimeRelations"]) {
                        int newid = [self checkAnimeRelations:((NSString *)[cacheentry valueForKey:@"id"]).intValue];
                        if (newid > 0) {
                            NSLog(@"Using Anime Relations mapping id...");
                            return @(newid).stringValue;
                        }
                    }
                }
            }
        }
    }
    return @"";
}
- (void)checkExceptions {
    // Check Exceptions
    NSManagedObjectContext * moc = self.managedObjectContext;
	bool found = false;
	NSPredicate *predicate;
    for (int i = 0; i < 3; i++) {
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        __block NSError * error = nil;
        if (i == 0) {
            NSLog(@"Check Exceptions List");
            allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
            if (_detectedscrobble.DetectedSeason > 1) {
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND (detectedSeason == %i)", _detectedscrobble.DetectedTitle, _detectedscrobble.DetectedSeason];
            }
            else {
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND ((detectedSeason == %i) OR (detectedSeason == %i))", _detectedscrobble.DetectedTitle, 0, 1];
            }
        }
        else if (i < 3 && [[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
                NSLog(@"Checking Auto Exceptions");
                allExceptions.entity = [NSEntityDescription entityForName:@"AutoCorrection" inManagedObjectContext:moc];
                if (_detectedscrobble.DetectedSeason == 1 || _detectedscrobble.DetectedSeason == 0) {
                    predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND ((group == %@) OR (group == %@))", _detectedscrobble.DetectedTitle, _detectedscrobble.DetectedGroup, @"ALL"];
                }
                else {
                    if (i == 1) {
                        predicate = [NSPredicate predicateWithFormat: @"((detectedTitle ==[c] %@) OR (detectedTitle ==[c] %@) OR (detectedTitle ==[c] %@)) AND ((group == %@) OR (group == %@))", [NSString stringWithFormat:@"%@ %i", _detectedscrobble.DetectedTitle, _detectedscrobble.DetectedSeason], [NSString stringWithFormat:@"%@ S%i", _detectedscrobble.DetectedTitle, _detectedscrobble.DetectedSeason], [NSString stringWithFormat:@"%@ %@ Season", _detectedscrobble.DetectedTitle, [Utility numbertoordinal:_detectedscrobble.DetectedSeason]], _detectedscrobble.DetectedGroup, @"ALL"];
                    }
                    else {
                        predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND ((group == %@) OR (group == %@))", _detectedscrobble.DetectedTitle, _detectedscrobble.DetectedGroup, @"ALL"];
                    }
                }
        }
        else {
            break;
        }
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
                if ([_detectedscrobble.DetectedTitle caseInsensitiveCompare:(NSString *)[entry valueForKey:@"detectedTitle"]] == NSOrderedSame) {
                    correcttitle = (NSString *)[entry valueForKey:@"correctTitle"];
                    // Set Correct Title and Episode offset (if any)
                    int threshold = ((NSNumber *)[entry valueForKey:@"episodethreshold"]).intValue;
                    int offset = ((NSNumber *)[entry valueForKey:@"episodeOffset"]).intValue;
                    int tmpepisode = _detectedscrobble.DetectedEpisode.intValue - offset;
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
                    
                    if (i==1 && _detectedscrobble.DetectedTitleisEpisodeZero == true && iszeroepisode == true) {
                        NSLog(@"%@ zero episode is found on exceptions list as %@.", _detectedscrobble.DetectedTitle, correcttitle);
                        _detectedscrobble.DetectedTitle = correcttitle;
                        _detectedscrobble.DetectedEpisode = [NSString stringWithFormat:@"%i", mappedepisode];
                        _detectedscrobble.DetectedTitleisEpisodeZero = true;
                        found = true;
                        break;
                    }
                    else if (i==1 && _detectedscrobble.DetectedTitleisEpisodeZero == false && iszeroepisode == true) {
                        continue;
                    }
                    if ((tmpepisode > threshold && threshold != 0) || (tmpepisode <= 0 && threshold != 1 && i==0)||(tmpepisode <= 0 && i==1)) {
                        continue;
                    }
                    else {
                        NSLog(@"%@ found on exceptions list as %@.", _detectedscrobble.DetectedTitle, correcttitle);
                        if (tmpepisode > 0) {
                            _detectedscrobble.DetectedEpisode = [NSString stringWithFormat:@"%i", tmpepisode];
                        }
                        if (_detectedscrobble.DetectedSeason > 0 && i != 2) {
                            _detectedscrobble.DetectedSeason = 0;
                        }
                        _detectedscrobble.DetectedType = @"";
                        _detectedscrobble.DetectedTitle = correcttitle;
                        _detectedscrobble.DetectedTitleisEpisodeZero = false;
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
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(detectedtitle ==[c] %@) AND (detectedepisode ==[c] %@) AND (detectedtype ==[c] %@) AND (ismovie == %i) AND (iszeroepisode == %i) AND (detectedseason == %i) AND (source == %@) AND (service == %li)", _detectedscrobble.DetectedTitle, _detectedscrobble.DetectedEpisode, _detectedscrobble.DetectedType, _detectedscrobble.DetectedTitleisMovie, _detectedscrobble.DetectedTitleisEpisodeZero, _detectedscrobble.DetectedSeason, _detectedscrobble.DetectedSource, [Hachidori currentService]];
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
    AFOAuthCredential * cred = [Hachidori getCurrentFirstAccount];
    return cred.expired;
}
- (void)refreshtokenWithService:(int)service successHandler:(void (^)(bool success)) successHandler {
    AFOAuthCredential *cred;
    switch (service) {
        case 0: {
            cred =
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
                                                        successHandler(true);
                                                    }
                                                       failure:^(NSError *error) {
                                                           NSLog(@"Token cannot be refreshed: %@", error);
                                                           successHandler(false);
                                                       }];
            break;
        }
        case 1: {
            [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori - AniList"];
            AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:@"https://anilist.co/"]
                                                                             clientID:kanilistclient
                                                                               secret:kanilistsecretkey];
            [OAuth2Manager setUseHTTPBasicAuthentication:NO];
            [OAuth2Manager authenticateUsingOAuthWithURLString:@"api/v2/oauth/token"
                                                    parameters:@{@"grant_type":@"refresh_token", @"refresh_token":cred.refreshToken, @"redirect_uri" : @"hachidoriauth%3A%2F%2Fanilistauth%2F"} success:^(AFOAuthCredential *credential) {
                                                        NSLog(@"Token refreshed");
                                                        [AFOAuthCredential storeCredential:credential
                                                                            withIdentifier:@"Hachidori - AniList"];
                                                        successHandler(true);
                                                    }
                                                       failure:^(NSError *error) {
                                                           NSLog(@"Token cannot be refreshed: %@", error);
                                                           successHandler(false);
                                                       }];
            break;
        }
        default:
            break;
    }
}

- (void)retrieveUserID:(void (^)(int userid, NSString *username, NSString *scoreformat)) completionHandler error:(void (^)(NSError * error)) errorHandler withService:(int)service {
    AFOAuthCredential *cred = [Hachidori getFirstAccount:service];
    if (cred && cred.expired) {
        errorHandler(nil);
        return;
    }
    [_asyncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    switch (service) {
        case 0: {
            [_asyncmanager GET:@"https://kitsu.io/api/edge/users?filter[self]=true&fields[users]=name,slug,avatar,ratingSystem" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if (((NSArray *)responseObject[@"data"]).count > 0) {
                    NSDictionary *d = [NSArray arrayWithArray:responseObject[@"data"]][0];
                    int scoreformat = 0;
                    NSString *ratingtype = d[@"attributes"][@"ratingSystem"];
                    if (ratingtype) {
                        if ([ratingtype isEqualToString:@"simple"]) {
                            scoreformat = ratingSimple;
                        }
                        else if ([ratingtype isEqualToString:@"standard"]) {
                            scoreformat = ratingStandard;
                        }
                        else if ([ratingtype isEqualToString:@"advanced"]) {
                            scoreformat = ratingAdvanced;
                        }
                    }
                    else {
                        scoreformat = ratingSimple;
                    }
                    NSString *username = @"Unknown User";
                    if (d[@"attributes"][@"name"] != [NSNull null]) {
                        username = d[@"attributes"][@"name"];
                    }
                    else if (d[@"attributes"][@"slug"] != [NSNull null]) {
                        username = d[@"attributes"][@"slug"];
                    }
                    completionHandler(((NSNumber *)d[@"id"]).intValue,username, @(scoreformat).stringValue);
                }
                else {
                    completionHandler(-1,@"",@"");
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                errorHandler(error);
            }];
            break;
        }
        case 1: {
            [_asyncmanager POST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistCurrentUsernametoUserId, @"variables" : @{}} progress:nil success:^(NSURLSessionTask *task, id responseObject) {
                if (responseObject[@"data"][@"Viewer"] != [NSNull null]) {
                    NSDictionary *d = responseObject[@"data"][@"Viewer"];
                    completionHandler(((NSNumber *)d[@"id"]).intValue,d[@"name"], d[@"mediaListOptions"][@"scoreFormat"]);
                }
                else {
                    completionHandler(-1,@"",@"");
                }
            } failure:^(NSURLSessionTask *operation, NSError *error) {
                errorHandler(error);
            }];
            break;
        }
        default:
            break;
    }

}

- (void)resetinfo {
    // Resets Hachidori Engine when user logs out
    _lastscrobble = nil;
    _detectedscrobble = nil;
}

- (void)setNotifier {
    if (_reach) {
        [_reach stopNotifier];
    }
    //Create Reachability Object
    switch ([Hachidori currentService]) {
        case 0:
            _reach = [Reachability reachabilityWithHostname:@"kitsu.io"];
            break;
        case 1:
            _reach = [Reachability reachabilityWithHostname:@"anilist.co"];
            break;
    }
    _reach.reachableBlock = ^(Reachability*reach)
    {
        online = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@ is reachable.", [Hachidori currentServiceName]);
        });
    };
    _reach.unreachableBlock = ^(Reachability*reach)
    {
        online = false;
        NSLog(@"Computer not connected to internet or %@ is down", [Hachidori currentServiceName]);
    };
    // Start notifier
    [_reach startNotifier];
}

- (void)sendDiscordPresence:(LastScrobbleStatus *)lscrobble {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"usediscordrichpresence"] && self.discordmanager.discordrpcrunning) {
        [self.discordmanager UpdatePresence:[NSString stringWithFormat:@"%@ Episode %@ ", lscrobble.WatchStatus,self.lastscrobble.LastScrobbledEpisode] withDetails:[NSString stringWithFormat:@"%@",  lscrobble.LastScrobbledActualTitle]];
    }
}

- (void)setLastScrobble {
    switch ([Hachidori currentService]) {
        case 0:
            _lastscrobble = _kitsumanager.lastscrobble;
            break;
        case 1:
            _lastscrobble = _anilistmanager.lastscrobble;
            break;
    }
}

- (void)setDetectScrobble:(DetectedScrobbleStatus *)dscrobble {
    switch ([Hachidori currentService]) {
        case 0:
            _kitsumanager.detectedscrobble = dscrobble;
            _detectedscrobble = _kitsumanager.detectedscrobble;
            break;
        case 1:
            _anilistmanager.detectedscrobble = dscrobble;
            _detectedscrobble = _anilistmanager.detectedscrobble;
            break;
    }
}

- (void)clearLastScrobbled {
    _lastscrobble = nil;
    _kitsumanager.lastscrobble = nil;
    _anilistmanager.lastscrobble = nil;
}

- (void)clearDetectedScrobbled {
    _detectedscrobble = nil;
    _kitsumanager.detectedscrobble = nil;
    _anilistmanager.detectedscrobble = nil;
}

- (void)resetInfoWithService:(int)service {
    _lastscrobble = nil;
    _detectedscrobble = nil;
    switch (service) {
        case 0:
            _kitsumanager.detectedscrobble = nil;
            _kitsumanager.detectedscrobble = nil;
            break;
        case 1:
            _anilistmanager.detectedscrobble = nil;
            _anilistmanager.detectedscrobble = nil;
            break;
    }
}

- (void)switchScrobbleStatus {
    switch ([Hachidori currentService]) {
        case 0:
            _lastscrobble = _kitsumanager.lastscrobble;
            _detectedscrobble = _kitsumanager.detectedscrobble;
            break;
        case 1:
            _lastscrobble = _anilistmanager.lastscrobble;
            _detectedscrobble = _anilistmanager.detectedscrobble;
            break;
    }
}

- (int)getUserRatingType {
    //Set OAuth Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    switch ([Hachidori currentService]) {
        case 0:
            responseObject = [self.syncmanager syncGET:@"https://kitsu.io/api/edge/users?filter[self]=true" parameters:nil task:&task error:&error];
            break;
        case 1:
            responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistCurrentUsernametoUserId, @"variables" : @{}} task:&task error:&error];
            break;
        default:
            return 0;
    }
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200 || statusCode == 201 ) {
        switch ([Hachidori currentService]) {
            case 0: {
                if (((NSArray *)responseObject[@"data"]).count > 0) {
                    NSDictionary *d = [NSArray arrayWithArray:responseObject[@"data"]][0];
                    NSString *ratingtype = d[@"attributes"][@"ratingSystem"];
                    if ([ratingtype isEqualToString:@"simple"]) {
                        return ratingSimple;
                    }
                    else if ([ratingtype isEqualToString:@"standard"]) {
                        return ratingStandard;
                    }
                    else if ([ratingtype isEqualToString:@"advanced"]) {
                        return ratingAdvanced;
                    }
                }
                break;
            }
            case 1: {
                if (responseObject[@"data"][@"Viewer"] != [NSNull null]) {
                    NSDictionary *d = responseObject[@"data"][@"Viewer"];
                    NSString *ratingtype = d[@"mediaListOptions"][@"scoreFormat"];
                    if ([ratingtype isEqualToString:@"POINT_100"]) {
                        return ratingPoint100;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_10_DECIMAL"]) {
                        return ratingPoint10Decimal;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_10"]) {
                        return ratingPoint10;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_5"]) {
                        return ratingPoint5;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_3"]) {
                        return ratingPoint3;
                    }
                    else {
                        return ratingPoint100;
                    }
                }
                else {
                    return ratingPoint100;
                }
                break;
            }
        }
        
    }
    return ratingSimple;
}
@end
