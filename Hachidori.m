//
//  Hachidori.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import "Detection.h"
#import "Hachidori+Keychain.h"
#import "Hachidori+Search.h"
#import "Hachidori+Update.h"
#import "Hachidori+UserStatus.h"
#import "ClientConstants.h"
#import "AppDelegate.h"
#import "Reachability.h"


@implementation Hachidori
@synthesize managedObjectContext;
@synthesize online;
-(instancetype)init{
    confirmed = true;
    //Create Reachability Object
    reach = [Reachability reachabilityWithHostname:@"kitsu.io"];
    // Set up blocks
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        online = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Kitsu is reachable.");
        });
    };
    reach.unreachableBlock = ^(Reachability*reach)
    {
        online = false;
        NSLog(@"Computer not connected to internet or Kitsu is down");
    };
    // Start notifier
    [reach startNotifier];
    //Set up Kodi Reachability
    [self setKodiReach:[[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]];
    return [super init];
}
-(void)setManagedObjectContext:(NSManagedObjectContext *)context{
    managedObjectContext = context;
}
/* 
 
 Accessors
 
 */
-(NSString *)getLastScrobbledTitle
{
    return LastScrobbledTitle;
}
-(NSString *)getLastScrobbledEpisode
{
    return LastScrobbledEpisode;
}
-(NSString *)getLastScrobbledActualTitle{
    return LastScrobbledActualTitle;
}
-(NSString *)getLastScrobbledSource{
    return LastScrobbledSource;
}
-(NSString *)getFailedTitle{
    return FailedTitle;
}
-(NSString *)getFailedEpisode{
    return FailedEpisode;
}
-(NSString *)getAniID
{
    return AniID;
}
-(int)getTotalEpisodes
{
	return TotalEpisodes;
}
-(float)getScore
{
    return TitleScore;
}
-(int)getCurrentEpisode{
    return DetectedCurrentEpisode;
}
-(BOOL)getConfirmed{
    return confirmed;
}
-(BOOL)getRewatching{
    return rewatching;
}
-(BOOL)getisNewTitle{
    return LastScrobbledTitleNew;
}
-(int)getWatchStatus
{
	if ([WatchStatus isEqualToString:@"currently-watching"])
		return 0;
	else if ([WatchStatus isEqualToString:@"completed"])
		return 1;
	else if ([WatchStatus isEqualToString:@"on-hold"])
		return 2;
	else if ([WatchStatus isEqualToString:@"dropped"])
		return 3;
    else if ([WatchStatus isEqualToString:@"plan-to-watch"])
        return 4;
	else
		return 0; //fallback
}
-(BOOL)getSuccess{
    return Success;
}
-(NSDictionary *)getLastScrobbledInfo{
    return LastScrobbledInfo;
}
-(NSString *)getNotes{
    return TitleNotes;
}
-(BOOL)getPrivate{
    return isPrivate;
}
-(NSString *)getSlug{
    return slug;
}
-(int)getQueueCount{
    NSError * error;
    NSManagedObjectContext * moc = self.managedObjectContext;
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND (status == %i)", false, 23];
    NSFetchRequest * queuefetch = [[NSFetchRequest alloc] init];
    queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
    [queuefetch setPredicate: predicate];
    NSArray * queue = [moc executeFetchRequest:queuefetch error:&error];
    int count = (int)queue.count;
    [managedObjectContext reset];
    return count;
}
-(AFOAuthCredential *)getFirstAccount{
   return [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori"];
}
-(NSString *)getUserid{
    NSString * userid = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserID"];
    if (userid){
        return userid;
    }
    return nil;
}
/*
 
 Update Methods
 
 */

- (int)startscrobbling {
    // 0 - nothing playing; 1 - same episode playing; 2 - No Update Needed; 3 - Confirm title before adding  21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed - 23 - Offline Queue;;
    int detectstatus = [self detectmedia];
	if (detectstatus == 2) { // Detects Title
        if (online){
            return [self scrobble];
            // Empty out Detected Title/Episode to prevent same title detection
            DetectedTitle = nil;
            DetectedEpisode = nil;
            DetectedSource = nil;
            DetectedGroup = nil;
            DetectedType = nil;
            DetectedSeason = 0;
            // Clear Core Data Objects from Memory
            [managedObjectContext reset];
            // Reset correcting Value
            correcting = false;
        }
        else{
            NSError * error;
            if (![self checkifexistinqueue]) {
                // Store in offline queue
                NSManagedObject *obj = [NSEntityDescription
                                        insertNewObjectForEntityForName:@"OfflineQueue"
                                        inManagedObjectContext: managedObjectContext];
                // Set values in the new record
                [obj setValue:DetectedTitle forKey:@"detectedtitle"];
                [obj setValue:DetectedEpisode forKey:@"detectedepisode"];
                [obj setValue:DetectedType forKey:@"detectedtype"];
                [obj setValue:DetectedSource forKey:@"source"];
                [obj setValue:[NSNumber numberWithInteger:DetectedSeason] forKey:@"detectedseason"];
                [obj setValue:[NSNumber numberWithBool:DetectedTitleisMovie] forKey:@"ismovie"];
                [obj setValue:[NSNumber numberWithBool:DetectedTitleisEpisodeZero] forKey:@"iszeroepisode"];
                [obj setValue:[NSNumber numberWithInteger:23] forKey:@"status"];
                [obj setValue:[NSNumber numberWithBool:false] forKey:@"scrobbled"];
                //Save
                [managedObjectContext save:&error];
            }
            // Store Last Scrobbled Title
            LastScrobbledTitle = DetectedTitle;
            LastScrobbledEpisode = DetectedEpisode;
            DetectedCurrentEpisode = [DetectedEpisode intValue];
            LastScrobbledSource = DetectedSource;
            LastScrobbledActualTitle = DetectedTitle;
            confirmed = true;
            // Reset Detected Info
            DetectedTitle = nil;
            DetectedEpisode = nil;
            DetectedSource = nil;
            DetectedGroup = nil;
            DetectedType = nil;
            DetectedSeason = 0;
            Success = true;
            [managedObjectContext reset];
            return 23;
        }
	}
    return detectstatus;
}
-(NSDictionary *)scrobblefromqueue{
    // Restore Detected Media
    NSError * error;
    NSManagedObjectContext * moc = self.managedObjectContext;
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(scrobbled == %i) AND ((status == %i) OR (status == %i))", false, 23, 3];
    NSFetchRequest * queuefetch = [[NSFetchRequest alloc] init];
    queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
    [queuefetch setPredicate: predicate];
    NSArray * queue = [moc executeFetchRequest:queuefetch error:&error];
    int successc = 0;
    int fail = 0;
    bool confirmneeded = false;
    if (queue.count > 0) {
        for (NSManagedObject * item in queue){
            // Restore detected title and episode from coredata
            DetectedTitle = [item valueForKey:@"detectedtitle"];
            DetectedEpisode = [item valueForKey:@"detectedepisode"];
            DetectedSource = [item valueForKey:@"source"];
            DetectedType = [item valueForKey:@"detectedtype"];
            DetectedSeason = [[item valueForKey:@"detectedseason"] intValue];
            DetectedTitleisMovie = [[item valueForKey:@"ismovie"] boolValue];
            DetectedTitleisEpisodeZero = [[item valueForKey:@"iszeroepisode"] boolValue];
            int result = [self scrobble];
            bool scrobbled;
            NSManagedObject * record = [self checkifexistinqueue];
            // Record Results
            [record setValue:[NSNumber numberWithInteger:result] forKey:@"status"];
            // 0 - nothing playing; 1 - same episode playing; 2 - No Update Needed; 3 - Confirm title before updating  21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed - 23 - Offline Queue;
            switch (result) {
                case 51:
                case 52:
                case 53:
                case 54:
                    fail++;
                    scrobbled = false;
                    break;
                case 3:
                    successc++;
                    scrobbled = true;
                    break;
                default:
                    successc++;
                    scrobbled = true;
                    break;
            }
            [record setValue:[NSNumber numberWithBool:scrobbled] forKey:@"scrobbled"];
            [moc save:&error];
            
            //Save
            if (result == 3){
                confirmneeded = true;
                break;
            }
        }
    }
    if (successc > 0){
        Success = true;
    }
    return @{@"success": [NSNumber numberWithInt:successc], @"fail": [NSNumber numberWithInt:fail], @"confirmneeded" : [NSNumber numberWithBool:confirmneeded]};
}
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)correctonce{
    correcting = true;
    NSString * lasttitle;
    if (correctonce) {
        lasttitle = LastScrobbledTitle;
    }
    DetectedTitle = showtitle;
    DetectedEpisode = episode;
    if (FailedSource == nil) {
        DetectedSource = LastScrobbledSource;
    }
    else{
        DetectedSource = FailedSource;
    }
    // Check Exceptions
    [self checkExceptions];
    // Scrobble and return status code
    int status = [self scrobble];
    if (correctonce) {
        LastScrobbledTitle = lasttitle; //Set the Last Scrobbled Title to exact title.
    }
    return status;
}
-(int)scrobble{
    int status;
	NSLog(@"=============");
	NSLog(@"Scrobbling...");
    NSLog(@"Getting AniID");
    // Regular Search
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        // Check Cache
        NSString *theid = [self checkCache];
        if (theid.length == 0)
            AniID = [self searchanime]; // Not in cache, search
        else{
            AniID = theid; // Set cached show id as AniID
            //If Detected Episode is missing, set it to 1 for sanity
            if (DetectedEpisode.length == 0) {
                DetectedEpisode = @"1";
            }
        }
    }
    else{
        AniID = [self searchanime]; // Search Cache Disabled
    }
    if (AniID.length > 0) {
        NSLog(@"Found %@", AniID);
        // Nil out Failed Title and Episode
        FailedTitle = nil;
        FailedEpisode = nil;
        FailedSource = nil;
        // Check Status and Update
        BOOL UpdateBool = [self checkstatus:AniID];
        if (UpdateBool == 1) {
            if (LastScrobbledTitleNew) {
                //Title is not on list. Add Title
                int s = [self updatetitle:AniID];
                if (s == 21 || s == 3) {
                    Success = true;}
                else{
                    Success = false;}
                status = s;
            }
            else {
                // Update Title as Usual
                int s = [self updatetitle:AniID];
                if (s == 2 || s == 3 ||s == 22 ) {
                    Success = true;
                }
                else{
                    Success = false;}
                status = s;
            }
        }
        else{
            if (_online) {
                 status = 54;
            }
            else{
                status = 55;
            }
        }
    }
    else {
        if (_online) {
            // Not Successful
            NSLog(@"Error: Couldn't find title %@. Please add an Anime Exception rule.", DetectedTitle);
            // Used for Exception Adding
            FailedTitle = DetectedTitle;
            FailedEpisode = DetectedEpisode;
            FailedSource = DetectedSource;
            status = 51;
        }
        else{
            status = 55;
        }
        
    }
    NSLog(@"Scrobble Complete with Status Code: %i", status);
    NSLog(@"=============");
    // Release Detected Title/Episode.
    return status;
}
-(NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type{
    //For unit testing only
    DetectedTitle = title;
    DetectedEpisode = episode;
    DetectedSeason = season;
    DetectedGroup = group;
    DetectedType = type;
    unittesting = true;
    //Check for zero episode as the detected episode
    [self checkzeroEpisode];
    //Check for Exceptions
    [self checkExceptions];
    //Retrieve Info
    NSDictionary * d = [self retrieveAnimeInfo:[self searchanime]];
    return d;
}
-(int)detectmedia {
    NSDictionary * result = [Detection detectmedia];
    if (result !=nil) {
        //Populate Data
        DetectedTitle = result[@"detectedtitle"];
        DetectedEpisode = result[@"detectedepisode"];
        DetectedSeason = ((NSNumber *)result[@"detectedseason"]).intValue;
        DetectedGroup = result[@"group"];
        DetectedSource = result[@"detectedsource"];
        if (((NSArray *)result[@"types"]).count > 0) {
            DetectedType = (result[@"types"])[0];
        }
        else{
            DetectedType = @"";
        }
        //Check for zero episode as the detected episode
        [self checkzeroEpisode];
        // Check if the title was previously scrobbled
        [self checkExceptions];
        if ([DetectedTitle isEqualToString:LastScrobbledTitle] && ([DetectedEpisode isEqualToString: LastScrobbledEpisode]||[self checkBlankDetectedEpisode]) && Success == 1) {
            // Do Nothing
            return 1;
        }
        else {
            // Not Scrobbled Yet or Unsuccessful
            return 2;
        }
    }
    else{
        return 0;
    }
}
-(BOOL)checkBlankDetectedEpisode{
    if ([LastScrobbledEpisode isEqualToString:@"1"] && DetectedEpisode.length ==0) {
        return true;
    }
    return false;
}
-(void)checkzeroEpisode{
    // For 00 Episodes
    if ([DetectedEpisode isEqualToString:@"00"]||[DetectedEpisode isEqualToString:@"0"]) {
        DetectedEpisode = @"1";
        DetectedTitleisEpisodeZero = true;
    }
    else if ([DetectedType isLike:@"Movie"] && ([DetectedEpisode isEqualToString:@"0"] || DetectedEpisode.length == 0)){
        DetectedEpisode = @"1";
    }
    else{DetectedTitleisEpisodeZero = false;}
}
-(BOOL)confirmupdate{
    DetectedTitle = LastScrobbledTitle;
    DetectedEpisode = LastScrobbledEpisode;
    DetectedSource  = LastScrobbledSource;
    NSLog(@"=============");
    NSLog(@"Confirming: %@ - %@",LastScrobbledActualTitle, LastScrobbledEpisode);
    int status = [self performupdate:AniID];
    switch (status) {
        case 21:
        case 22:
            // Clear Detected Episode and Title
            DetectedTitle = nil;
            DetectedEpisode = nil;
            DetectedSource = nil;
            return true;
        default:
            return false;
    }
}
-(void)clearAnimeInfo{
    LastScrobbledInfo = nil;
}
-(NSString *)checkCache{
    NSManagedObjectContext *moc = managedObjectContext;
    NSFetchRequest * allCaches = [[NSFetchRequest alloc] init];
    allCaches.entity = [NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", DetectedTitle];
    allCaches.predicate = predicate;
    NSError * error = nil;
    NSArray * cache = [moc executeFetchRequest:allCaches error:&error];
    if (cache.count > 0) {
        for (NSManagedObject * cacheentry in cache) {
            NSString * title = [cacheentry valueForKey:@"detectedTitle"];
            if ([title isEqualToString:DetectedTitle]) {
                NSLog(@"%@ found in cache!", title);
                // Total Episode check
                NSNumber * totalepisodes = [cacheentry valueForKey:@"totalEpisodes"];
                if ( DetectedEpisode.intValue <= totalepisodes.intValue || totalepisodes.intValue == 0 ) {
                    return [cacheentry valueForKey:@"id"];
                }
            }
        }
    }
    return @"";
}
-(void)checkExceptions{
    // Check Exceptions
    NSManagedObjectContext * moc = self.managedObjectContext;
	bool found = false;
	NSPredicate *predicate;
    for (int i = 0; i < 2; i++) {
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        NSError * error = nil;
        if (i == 0) {
            NSLog(@"Check Exceptions List");
            allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
			predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", DetectedTitle];
        }
        else if (i== 1 && [[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]){
                NSLog(@"Checking Auto Exceptions");
                allExceptions.entity = [NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc];
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND ((group == %@) OR (group == %@))", DetectedTitle, DetectedGroup, @"ALL"];
        }
        else{break;}
		// Set Predicate and filter exceiptions array
        [allExceptions setPredicate: predicate];
        NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
        if (exceptions.count > 0) {
            NSString * correcttitle;
            for (NSManagedObject * entry in exceptions) {
                NSLog(@"%@",(NSString *)[entry valueForKey:@"detectedTitle"]);
                if ([DetectedTitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]]) {
                    correcttitle = (NSString *)[entry valueForKey:@"correctTitle"];
                    // Set Correct Title and Episode offset (if any)
                    int threshold = ((NSNumber *)[entry valueForKey:@"episodethreshold"]).intValue;
                    int offset = ((NSNumber *)[entry valueForKey:@"episodeOffset"]).intValue;
                    int tmpepisode = DetectedEpisode.intValue - offset;
                    int mappedepisode = [(NSNumber *)[entry valueForKey:@"mappedepisode"] intValue];
                    bool iszeroepisode = [(NSNumber *)[entry valueForKey:@"iszeroepisode"] boolValue];
                    if (i==1 && DetectedTitleisEpisodeZero == true && iszeroepisode == true){
                        NSLog(@"%@ zero episode is found on exceptions list as %@.", DetectedTitle, correcttitle);
                        DetectedTitle = [correcttitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                        DetectedEpisode = [NSString stringWithFormat:@"%i", mappedepisode];
                        DetectedTitleisEpisodeZero = true;
                        found = true;
                        break;
                    }
                    else if (i==1 && DetectedTitleisEpisodeZero == false && iszeroepisode == true){
                        continue;
                    }
                    if ((tmpepisode > threshold && threshold != 0) || (tmpepisode <= 0 && threshold != 1 && i==0)||(tmpepisode <= 0 && i==1)) {
                        continue;
                    }
                    else {
                        NSLog(@"%@ found on exceptions list as %@.", DetectedTitle, correcttitle);
                        DetectedTitle = [correcttitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                        if (tmpepisode > 0) {
                            DetectedEpisode = [NSString stringWithFormat:@"%i", tmpepisode];
                        }
                        DetectedSeason = 0;
                        DetectedTitleisEpisodeZero = false;
                        found = true;
						break;
                    }
                }
            }
			if (found){break;} //Break from exceptions check loop
        }
    }
}
-(NSManagedObject *)checkifexistinqueue{
    // Return existing offline queue item
    NSError * error;
    NSManagedObjectContext * moc = self.managedObjectContext;
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(detectedtitle ==[c] %@) AND (detectedepisode ==[c] %@) AND (detectedtype ==[c] %@) AND (ismovie == %i) AND (iszeroepisode == %i) AND (detectedseason == %i) AND (source == %@)", DetectedTitle, DetectedEpisode, DetectedType, DetectedTitleisMovie, DetectedTitleisEpisodeZero, DetectedSeason, DetectedSource];
    NSFetchRequest * queuefetch = [[NSFetchRequest alloc] init];
    queuefetch.entity = [NSEntityDescription entityForName:@"OfflineQueue" inManagedObjectContext:moc];
    [queuefetch setPredicate: predicate];
    NSArray * queue = [moc executeFetchRequest:queuefetch error:&error];
    if (queue.count > 0) {
        return (NSManagedObject *)queue[0];
    }
    return nil;
}
-(void)setKodiReach:(BOOL)enable{
    if (enable == 1) {
        //Create Reachability Object
        kodireach = [Reachability reachabilityWithHostname:(NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"kodiaddress"]];
        // Set up blocks
        kodireach.reachableBlock = ^(Reachability*reach)
        {
            _kodionline = true;
        };
        kodireach.unreachableBlock = ^(Reachability*reach)
        {
            _kodionline = false;
        };
        // Start notifier
        [kodireach startNotifier];
    }
    else{
        [kodireach stopNotifier];
        kodireach = nil;
    }
}
-(void)setKodiReachAddress:(NSString *)url{
    [kodireach stopNotifier];
    kodireach = [Reachability reachabilityWithHostname:url];
    // Set up blocks
    // Set the blocks
    kodireach.reachableBlock = ^(Reachability*reach)
    {
        _kodionline = true;
    };
    kodireach.unreachableBlock = ^(Reachability*reach)
    {
        _kodionline = false;
    };
    // Start notifier
    [kodireach startNotifier];
}
/*
 Token Refresh
 */
-(bool)checkexpired{
    AFOAuthCredential * cred = [self getFirstAccount];
    return cred.expired;
}
-(void)refreshtoken{
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
        AppDelegate * appdel = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        [appdel updatenow:self];
    }
                                               failure:^(NSError *error) {
                                                   NSLog(@"Token cannot be refreshed: %@", error);
                                               }];
   
}

@end
