//
//  Hachidori.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import "Detection.h"
#import "Recognition.h"
#import "EasyNSURLConnection.h"

@interface Hachidori ()
// Private Methods
-(int)detectmedia; // 0 - Nothing, 1 - Same, 2 - Update
-(NSString *)searchanime;
-(NSString *)performSearch:(NSString *)searchtitle;
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term;
-(BOOL)checkstatus:(NSString *)titleid;
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug;
-(int)updatetitle:(NSString *)titleid;
-(NSString *)desensitizeSeason:(NSString *)title;
-(void)populateStatusData:(NSDictionary *)d;
-(void)addtoCache:(NSString *)title showid:(NSString *)showid actualtitle:(NSString *) atitle totalepisodes:(int)totalepisodes;
-(bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OGRegularExpression *)regex
           option:(int)i;
@end

@implementation Hachidori
@synthesize managedObjectContext;
-(id)init{
    confirmed = true;
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
-(NSString *)getTotalEpisodes
{
	return TotalEpisodes;
}
-(int)getScore
{
    return [TitleScore integerValue];
}
-(int)getCurrentEpisode{
    return [DetectedCurrentEpisode intValue];
}
-(BOOL)getConfirmed{
    return confirmed;
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
-(BOOL)checktoken{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"Token"] length] == 0) {
        return false;
    }
    else
        return true;
}
/*
 
 Update Methods
 
 */

- (int)startscrobbling {
    // 0 - nothing playing; 1 - same episode playing; 2 - No Update Needed; 3 - Confirm title before adding  21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed;
    int detectstatus;
	//Set up Delegate
	
    detectstatus = [self detectmedia];
	if (detectstatus == 2) { // Detects Title
        return [self scrobble];
	}

    return detectstatus;
}
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode{
    correcting = true;
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
    return [self scrobble];
}
-(int)scrobble{
    int status;
	NSLog(@"=============");
	NSLog(@"Scrobbling...");
    NSLog(@"Getting AniID");
    // Regular Search
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        NSManagedObjectContext *moc = managedObjectContext;
        NSFetchRequest * allCaches = [[NSFetchRequest alloc] init];
        [allCaches setEntity:[NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", DetectedTitle];
        [allCaches setPredicate:predicate];
        NSError * error = nil;
        NSArray * cache = [moc executeFetchRequest:allCaches error:&error];
        if (cache.count > 0) {
            NSString * theid;
            for (NSManagedObject * cacheentry in cache) {
                NSString * title = [cacheentry valueForKey:@"detectedTitle"];
                if ([title isEqualToString:DetectedTitle]) {
                    NSLog(@"%@ found in cache!", title);
                    // Total Episode check
                    NSNumber * totalepisodes = [cacheentry valueForKey:@"totalEpisodes"];
                    if ( [DetectedEpisode intValue] <= totalepisodes.intValue || totalepisodes.intValue == 0 ) {
                        theid = [cacheentry valueForKey:@"id"];
                        break;
                    }
                }
            }
            if (theid.length == 0) {
                AniID = [self searchanime]; // Not in cache, search
            }
            else{
                AniID = theid; // Set cached show id as AniID
            }
        }
        else{
            AniID = [self searchanime]; // Cache empty, search
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
            if (online) {
                 status = 54;
            }
            else{
                status = 55;
            }
        }
    }
    else {
        if (online) {
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
    // Empty out Detected Title/Episode to prevent same title detection
    DetectedTitle = nil;
    DetectedEpisode = nil;
    DetectedSource = nil;
    DetectedGroup = nil;
    DetectedSeason = 0;
    // Reset correcting Value
    correcting = false;
    NSLog(@"Scrobble Complete with Status Code: %i", status);
    NSLog(@"===========");
    // Release Detected Title/Episode.
    return status;
}
-(NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group{
    //For unit testing only
    DetectedTitle = title;
    DetectedEpisode = episode;
    DetectedSeason = season;
    DetectedGroup = group;
    unittesting = true;
    //Check for Exceptions
    [self checkExceptions];
    NSDictionary * d = [self retrieveAnimeInfo:[self searchanime]];
    return d;
}
-(NSString *)searchanime{
    // Searches for ID of associated title
    NSString * searchtitle = DetectedTitle;
    if (DetectedSeason > 1) {
        // Specifically search for season
        for (int i = 0; i < 2; i++) {
            NSString * tmpid;
            switch (i) {
                case 0:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i", [self desensitizeSeason:searchtitle], DetectedSeason]];
                    break;
                case 1:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i season", [self desensitizeSeason:searchtitle], DetectedSeason]];
                default:
                    break;
            }
            if (tmpid.length > 0) {
                return tmpid;
            }
        }
    }
    else{
        return [self performSearch:searchtitle]; //Perform Regular Search
    }
    return [self performSearch:searchtitle];
}
-(NSString *)performSearch:(NSString *)searchtitle{
    // Begin Search
    NSLog(@"Searching For Title");
    // Set Season for Search Term if any detected.
    //Escape Search Term
    NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)searchtitle,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/search/anime?query=%@", searchterm]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startRequest];
    //Set up Delegate
    
    // Get Status Code
    int statusCode = [request getStatusCode];
    NSData *response = [request getResponseData];
    switch (statusCode) {
        case 0:
            online = false;
            Success = NO;
            return @"";
            break;
        case 200:
            online = true;
            return [self findaniid:response searchterm:searchtitle];
            break;
            
        default:
            online = true;
            Success = NO;
            return @"";
            break;
    }

}
-(int)detectmedia {
    NSDictionary * result = [Detection detectmedia];
    if (result !=nil) {
        //Populate Data
        DetectedTitle = [result objectForKey:@"detectedtitle"];
        DetectedEpisode = [result objectForKey:@"detectedepisode"];
        DetectedSeason = [(NSNumber *)[result objectForKey:@"detectedseason"] intValue];
        DetectedGroup = [result objectForKey:@"detectedgroup"];
        DetectedSource = [result objectForKey:@"source"];
        // Check if the title was previously scrobbled
        [self checkExceptions];
        
        if ([DetectedTitle isEqualToString:LastScrobbledTitle] && [DetectedEpisode isEqualToString: LastScrobbledEpisode] && Success == 1) {
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
            break;
            
        default:
            return false;
            break;
    }
}
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term{
	// Initalize JSON parser
    NSError* error;
    
	NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
	NSString *titleid = @"";
	//Initalize NSString to dump the title temporarily
	NSString *theshowtitle = @"";
    NSString *alttitle = @"";
	//Create Regular Expression Strings
	NSString *findpre = [NSString stringWithFormat:@"(%@)",term];
    NSString *findinit = [NSString stringWithFormat:@"(%@)",term];
	findpre = [findpre stringByReplacingOccurrencesOfString:@" " withString:@"|"];
    OGRegularExpression    *regex;
	//Retrieve the ID. Note that the most matched title will be on the top
    // For Sanity (TV shows and OVAs usually have more than one episode)
    if(DetectedEpisode.length == 0){
        // Title is a movie
        NSLog(@"Title is a movie");
        DetectedTitleisMovie = true;
    }
    else{
        // Is TV Show
        NSLog(@"Title is not a movie.");
        DetectedTitleisMovie = false;
    }
    NSDictionary * found;
    // Create a filtered Arrays
    NSMutableArray * sortedArray;
    if (DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"Special"]]];
    }
    else{
        // Check if there is any type keywords. If so, only focus on that show type
        OGRegularExpression * check = [OGRegularExpression regularExpressionWithString:@"(Special|OVA|ONA)" options:OgreIgnoreCaseOption];
        if ([check matchInString:DetectedTitle]) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type LIKE %@)", [[check matchInString:DetectedTitle] matchedString]]]];
        }
        else{
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"TV"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"ONA"]]];
            if (DetectedSeason == 1 | DetectedSeason == 0) {
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"Special"]]];
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"OVA"]]];
            }
        }
    }
	searchdata = nil;
    // Search
    for (int i = 0; i < 2; i++) {
        switch (i) {
            case 0:
                regex = [OGRegularExpression regularExpressionWithString:findinit options:OgreIgnoreCaseOption];
                break;
            case 1:
                regex = [OGRegularExpression regularExpressionWithString:findpre options:OgreIgnoreCaseOption];
                break;
            default:
                break;
        }
    if (DetectedTitleisMovie) {
        //Check movies and Specials First
        for (NSDictionary *searchentry in sortedArray) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
            alttitle = [NSString stringWithFormat:@"%@", [searchentry objectForKey:@"alternate_title"]];
        if ([self checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
        }
            DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
            if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"show_type"]] isEqualToString:@"Special"]) {
                DetectedTitleisMovie = false;
            }
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
			found = searchentry;
            goto foundtitle;
        }
    }
    else{
    // Check TV, ONA, Special, OVA, Other
    for (NSDictionary *searchentry in sortedArray) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        alttitle = [NSString stringWithFormat:@"%@", [searchentry objectForKey:@"alternate_title"]];
        if ([self checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
            if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"show_type"]] isEqualToString:@"TV"]||[[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"show_type"]] isEqualToString:@"ONA"]) { // Check Seasons if the title is a TV show type
                // Used for Season Checking
                OGRegularExpression    *regex2 = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"(%i(st|nd|rd|th) season|\\W%i)", DetectedSeason, DetectedSeason] options:OgreIgnoreCaseOption];
                OGRegularExpressionMatch * smatch = [regex2 matchInString:[NSString stringWithFormat:@"%@ - %@ - %@", theshowtitle, alttitle, [searchentry objectForKey:@"slug"]]];
                if (DetectedSeason >= 2) { // Season detected, check to see if there is a matcch. If not, continue.
                    if (smatch == nil) {
                        continue;
                    }
                }
                else{
                    if (smatch != nil && DetectedSeason >= 2) { // No Season, check to see if there is a season or not. If so, continue.
                        continue;
                    }
                }
            }
            //Return titleid if episode is valid
            if ([searchentry objectForKey:@"episode_count"] == [NSNull null] || ([[NSString stringWithFormat:@"%@",[searchentry objectForKey:@"episode_count"]] intValue] >= [DetectedEpisode intValue])) {
                NSLog(@"Valid Episode Count");
				found = searchentry;
                titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
                goto foundtitle;
            }
            else{
                // Detected episodes exceed total episodes
                continue;
            }

        }
    }
    }
    }
    foundtitle:
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"] && titleid.length > 0 && !unittesting) {
        //Save AniID
        [self addtoCache:DetectedTitle showid:titleid actualtitle:(NSString *)[found objectForKey:@"title"] totalepisodes:[(NSNumber *)[found objectForKey:@"episodes"] intValue] ];
    }
	//Return the AniID
	return titleid;
}
-(BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking %@", titleid);
    //Set up Delegate
    
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@", titleid]];
   EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addFormData:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    // Get Information
    [request startFormRequest];
    NSDictionary * d;
    int statusCode = [request getStatusCode];
    NSError * error = [request getError];
	if (statusCode == 200 || statusCode == 201 ) {
        online = true;
        //return Data
        NSError * error;
        d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
                if ([d count] > 0) {
                    NSLog(@"Title on list");
                    [self populateStatusData:d];
                }
                else{
                    NSLog(@"Title not on list");
                    WatchStatus = @"currently-watching";
                    LastScrobbledInfo = [self retrieveAnimeInfo:AniID];
                    DetectedCurrentEpisode = @"0";
                    TitleScore  = @"0";
                    isPrivate = [defaults boolForKey:@"setprivate"];
                    TitleNotes = @"";
                    LastScrobbledTitleNew = true;
                }
		if ([LastScrobbledInfo objectForKey:@"episode_count"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
			TotalEpisodes = @"0"; // No Episode Total, Set to 0.
		}
		else { // Episode Total Exists
			TotalEpisodes = [LastScrobbledInfo  objectForKey:@"episode_count"];
		}
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && LastScrobbledTitleNew && !correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !LastScrobbledTitleNew && !correcting)) {
            // Manually confirm updates
            confirmed = false;
        }
        else{
            // Automatically confirm updates
            confirmed = true;
        }
		return YES;
	}
    else if (error !=nil){
        if (error.code == NSURLErrorNotConnectedToInternet) {
            online = false;
            return NO;
        }
        else {
            online = true;
            return NO;
        }
    }
	else {
		// Some Error. Abort
		return NO;
	}
	//Should never happen, but...
	return NO;
}
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug{
    NSLog(@"Getting Additional Info");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/anime/%@", slug]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Get Information
    [request startRequest];
    // Get Status Code
    int statusCode = [request getStatusCode];
    if (statusCode == 200) {
        NSError* error;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
        return d;
    }
    else{
        NSDictionary * d = [[NSDictionary alloc] init];
        return d;
    }
}
-(int)updatetitle:(NSString *)titleid {
	NSLog(@"Updating Title");
    if (LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && !confirmed && !correcting) {
        // Confirm before updating title
        LastScrobbledTitle = DetectedTitle;
        LastScrobbledEpisode = DetectedEpisode;
        LastScrobbledSource = DetectedSource;
        LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
        return 3;
    }
	if ([DetectedEpisode intValue] <= [DetectedCurrentEpisode intValue] ) {
		// Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
        LastScrobbledSource = DetectedSource;
        LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
        confirmed = true;
        return 2;
	}
    else if (!LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !confirmed && !correcting) {
        // Confirm before updating title
        LastScrobbledTitle = DetectedTitle;
        LastScrobbledEpisode = DetectedEpisode;
        LastScrobbledSource = DetectedSource;
        LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
        return 3;
    }
	else {
        return [self performupdate:titleid];
	}
}
-(int)performupdate:(NSString *)titleid{
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@", titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addFormData:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    //Set Timeout
    //[request setRequestMethod:@"PUT"];
    [request addFormData:DetectedEpisode forKey:@"episodes_watched"];
    //Set Status
    if([DetectedEpisode intValue] == [TotalEpisodes intValue]) {
        //Set Title State
        WatchStatus = @"completed";
        // Since Detected Episode = Total Episode, set the status as "Complete"
        [request addFormData:WatchStatus forKey:@"status"];
    }
    else {
        //Set Title State to currently watching
        WatchStatus = @"currently-watching";
        // Still Watching
        [request addFormData:WatchStatus forKey:@"status"];
    }
    // Set existing score to prevent the score from being erased.
    [request addFormData:TitleScore forKey:@"rating"];
    //Privacy
    if (isPrivate)
        [request addFormData:@"private" forKey:@"privacy"];
    else
        [request addFormData:@"public" forKey:@"privacy"];
    // Do Update
    [request startFormRequest];
    // Set correcting status to off
    correcting = false;
    switch ([request getStatusCode]) {
        case 201:
            // Store Scrobbled Title and Episode
            LastScrobbledTitle = DetectedTitle;
            LastScrobbledEpisode = DetectedEpisode;
            DetectedCurrentEpisode = LastScrobbledEpisode;
            LastScrobbledSource = DetectedSource;
            if (confirmed) { // Will only store actual title if confirmation feature is not turned on
                // Store Actual Title
                LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
            }
            confirmed = true;
            if (LastScrobbledTitleNew) {
                return 21;
            }
            // Update Successful
            return 22;
            break;
        default:
            // Update Unsuccessful
            if (LastScrobbledTitleNew) {
                return 52;
            }
            return 53;
            break;
    }

}
-(BOOL)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
			 score:(float)showscore
	   watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue
{
	NSLog(@"Updating Status for %@", titleid);
	//Set up Delegate
	
	// Update the title
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set library/scrobble API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@",  titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
	//Ignore Cookies
	[request setUseCookies:NO];
	//Set Token
    [request addFormData:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
	//Set current episode
    if ([episode intValue] != [DetectedCurrentEpisode intValue]) {
        [request addFormData:episode forKey:@"episodes_watched"];
    }
	//Set new watch status
	[request addFormData:showwatchstatus forKey:@"status"];	
	//Set new score.
	[request addFormData:[NSString stringWithFormat:@"%f", showscore] forKey:@"rating"];
    //Set new note
    [request addFormData:note forKey:@"notes"];
    //Privacy
    if (privatevalue)
        [request addFormData:@"private" forKey:@"privacy"];
    else
        [request addFormData:@"public" forKey:@"privacy"];
	// Do Update
	[request startFormRequest];
    switch ([request getStatusCode]) {
        case 200:
		case 201:
                //Set New Values
                TitleScore = [NSString stringWithFormat:@"%f", showscore];
                WatchStatus = showwatchstatus;
                TitleNotes = note;
                isPrivate = privatevalue;
                LastScrobbledEpisode = episode;
                DetectedCurrentEpisode = episode;
                return true;
			break;
		default:
			// Update Unsuccessful
                return false;
			break;
	}
    return false;
}
-(bool)removetitle:(NSString *)titleid{
    NSLog(@"Removing %@", titleid);
    //Set up Delegate
    
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@/remove", titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addFormData:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    // Do Update
    [request startFormRequest];
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            return true;
            break;
        default:
            // Update Unsuccessful
            return false;
            break;
    }
    return false;
}
-(void)populateStatusData:(NSDictionary *)d{
    // Info is there.
    NSDictionary * tmpinfo = [d objectForKey:@"anime"];
    WatchStatus = [d objectForKey:@"status"];
    //Get Notes;
    if ([d objectForKey:@"notes"] == [NSNull null]) {
        TitleNotes = @"";
    }
    else {
        TitleNotes = [d objectForKey:@"notes"];
    }
    // Get Rating
    NSDictionary * rating = [d objectForKey:@"rating"];
    if ([rating objectForKey:@"value"] == [NSNull null]){
        // Score is null, set to 0
        TitleScore = @"0";
    }
    else {
        TitleScore = [rating objectForKey:@"value"];
    }
    // Privacy Settings
    isPrivate = [[d objectForKey:@"private"] boolValue];
    DetectedCurrentEpisode = [d objectForKey:@"episodes_watched"];
    LastScrobbledInfo = tmpinfo;
    LastScrobbledTitleNew = false;
}
-(void)clearAnimeInfo{
    LastScrobbledInfo = nil;
}
-(NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OGRegularExpression* regex = [OGRegularExpression regularExpressionWithString: @"((first|second|third|fourth|fifth|sixth|seventh|eighth|nineth|(st|nd|rd|th)) season)" options:OgreIgnoreCaseOption];
    title = [regex replaceAllMatchesInString:title withString:@""];
    regex = [OGRegularExpression regularExpressionWithString: @"(s)\\d" options:OgreIgnoreCaseOption];
    title = [regex replaceAllMatchesInString:title withString:@""];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}
-(void)addtoCache:(NSString *)title showid:(NSString *)showid actualtitle:(NSString *) atitle totalepisodes:(int)totalepisodes {
    //Adds ID to cache
    NSManagedObjectContext *moc = managedObjectContext;
    // Add to Cache in Core Data
    NSManagedObject *obj = [NSEntityDescription
                            insertNewObjectForEntityForName :@"Cache"
                            inManagedObjectContext: moc];
    // Set values in the new record
    [obj setValue:title forKey:@"detectedTitle"];
    [obj setValue:showid forKey:@"id"];
    [obj setValue:atitle forKey:@"actualTitle"];
    [obj setValue:[NSNumber numberWithInt:totalepisodes] forKey:@"totalEpisodes"];
    NSError * error = nil;
    // Save
    [moc save:&error];

}
-(bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OGRegularExpression *)regex
           option:(int)i{
    //Checks for matches
    if ([regex matchInString:title] != nil || ([regex matchInString:atitle] != nil && [atitle length] >0 && i==0)) {
        return true;
    }
    return false;
}
-(void)checkExceptions{
    // Check Exceptions
    NSManagedObjectContext * moc = self.managedObjectContext;
	bool found = false;
    for (int i = 0; i < 2; i++) {
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        NSError * error = nil;
        if (i == 0) {
            NSLog(@"Check Exceptions List");
            [allExceptions setEntity:[NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc]];
        }
        else if (i== 1 && ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]||unittesting)){
                NSLog(@"Checking Auto Exceptions");
                [allExceptions setEntity:[NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc]];
        }
        else{break;}
        NSPredicate *predicate;
        switch (i) {
            case 0:
                predicate = [NSPredicate predicateWithFormat: @"detectedTitle == %@", DetectedTitle];
                break;
            case 1:
                predicate = [NSPredicate predicateWithFormat: @"(detectedTitle == %@) AND (group == %@)", DetectedTitle, DetectedGroup];
                break;
            default:
                break;
        }
        [allExceptions setPredicate:predicate];
        NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
        if (exceptions.count > 0) {
            NSString * correcttitle;
            for (NSManagedObject * entry in exceptions) {
                if ([DetectedTitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]]) {
                    correcttitle = (NSString *)[entry valueForKey:@"correctTitle"];
                    // Set Correct Title and Episode offset (if any)
                    int threshold = [(NSNumber *)[entry valueForKey:@"episodethreshold"] intValue];
                    int offset = [(NSNumber *)[entry valueForKey:@"episodeOffset"] intValue];
                    int tmpepisode = [DetectedEpisode intValue] - offset;
                    if ((tmpepisode > threshold && threshold != 0) || tmpepisode <= 0) {
                        continue;
                    }
                    else {
                        NSLog(@"%@ found on exceptions list as %@!", DetectedTitle, correcttitle);
                        DetectedTitle = correcttitle;
                        if (tmpepisode > 0) {
                            DetectedEpisode = [NSString stringWithFormat:@"%i", tmpepisode];
                        }
                        DetectedSeason = 0;
                        found = true;
						break;
                    }
                }
            }
			if (found){
				//Break from exceptions check loop
				break;
			}
        }

    }
}

@end
