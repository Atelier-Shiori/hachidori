//
//  Hachidori.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
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
-(NSDictionary *)detectStream;
-(void)populateStatusData:(NSDictionary *)d;
-(void)addtoCache:(NSString *)title showid:(NSString *)showid;
-(bool)checkMatch:(NSString *)title
         alttitle:(NSString *)atitle
            regex:(OGRegularExpression *)regex
           option:(int)i;
-(bool)checkifIgnored:(NSString *)filename;
@end

@implementation Hachidori
-(id)init{
    confirmed = true;
    return [super init];
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
    DetectedSource = LastScrobbledSource;
    return [self scrobble];
}
-(int)scrobble{
    int status;
    NSLog(@"Getting AniID");
    // Regular Search
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
        NSArray *cache = [[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"];
        if (cache.count > 0) {
            NSString * theid;
            for (NSDictionary *d in cache) {
                NSString * title = [d objectForKey:@"detectedtitle"];
                if ([title isEqualToString:DetectedTitle]) {
                    NSLog(@"%@ found in cache!", title);
                    theid = [d objectForKey:@"showid"];
                    break;
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
    DetectedSeason = 0;
    // Reset correcting Value
    correcting = false;
    // Release Detected Title/Episode.
    return status;
}
-(NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season{
    //For unit testing only
    DetectedTitle = title;
    DetectedEpisode = episode;
    DetectedSeason = season;
    unittesting = true;
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
    // LSOF mplayer to get the media title and segment
    
    NSArray * player = [NSArray arrayWithObjects:@"mplayer", @"mpv", @"mplayer-mt", @"VLC", @"QuickTime Playe", @"QTKitServer", @"Kodi", @"Movist", nil];
    NSString *string;
    OGRegularExpression    *regex;
    for(int i = 0; i <[player count]; i++){
        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/sbin/lsof"];
        [task setArguments: [NSArray arrayWithObjects:@"-c", (NSString *)[player objectAtIndex:i], @"-F", @"n", nil]]; 		//lsof -c '<player name>' -Fn
        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];
        
        NSFileHandle *file;
        file = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data;
        data = [file readDataToEndOfFile];
        
        string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        if (string.length > 0){
            regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm|rm|rmvb|wmv|divx|mov|flv|mpg|3gp)$" options:OgreIgnoreCaseOption];
            //Regex time
            //Get the filename first
            NSEnumerator    *enumerator;
            enumerator = [regex matchEnumeratorInString:string];
            OGRegularExpressionMatch    *match;
            while ((match = [enumerator nextObject]) != nil) {
                string = [match matchedString];
            }
            //Check if thee file name or directory is on any ignore list
            BOOL onIgnoreList = [self checkifIgnored:string];
            //Make sure the file name is valid, even if player is open. Do not update video files in ignored directories
            if ([regex matchInString:string] !=nil && !onIgnoreList) {
                NSDictionary *d = [[Recognition alloc] recognize:string];
                DetectedTitle = (NSString *)[d objectForKey:@"title"];
                DetectedEpisode = (NSString *)[d objectForKey:@"episode"];
                DetectedSeason = [[d objectForKey:@"season"] intValue];
                // Source Detection
                switch (i) {
                    case 0:
                    case 1:
                    case 3:
                    case 6:
					case 7:
                        DetectedSource = (NSString *)[player objectAtIndex:i];
                        break;
                    case 2:
                        DetectedSource = @"SMPlayerX";
                        break;
                    case 4:
                    case 5:
                        DetectedSource = @"Quicktime";
                        break;
                    default:
                        break;
                }
                break;
            }
        }
    }
    if (DetectedTitle.length > 0) {
        goto update;
    }
    else {
        // Check for Legal Streaming Sites
        NSLog(@"Checking Stream...");
        NSDictionary * detected = [self detectStream];
        
        if ([detected objectForKey:@"result"]  == [NSNull null]){ // Check to see if anything is playing on stream
            return 0;
        }
        else{
            NSArray * c = [detected objectForKey:@"result"];
            NSDictionary * d = [c objectAtIndex:0];
            DetectedTitle = (NSString *)[d objectForKey:@"title"];
            DetectedEpisode = (NSString *)[d objectForKey:@"episode"];
            DetectedSource = [NSString stringWithFormat:@"%@ in %@", (NSString *)[[d objectForKey:@"site"] capitalizedString], [d objectForKey:@"browser"]];
            goto update;
        }
        // Nothing detected
    }
update:
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
-(BOOL)confirmupdate{
    DetectedTitle = LastScrobbledTitle;
    DetectedEpisode = LastScrobbledEpisode;
    DetectedSource  = LastScrobbledSource;
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
    
    // Create a filtered Arrays
    NSMutableArray * sortedArray;
    if (DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"Special"]]];
    }
    else{
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"TV"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"ONA"]]];
        if (DetectedSeason == 1 | DetectedSeason == 0) {
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"Special"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"OVA"]]];
        }
    }
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
            goto foundtitle;
        }
    }
    else{
    // Check TV, ONA, Special, OVA, Other
    for (NSDictionary *searchentry in sortedArray) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        alttitle = [NSString stringWithFormat:@"%@", [searchentry objectForKey:@"alternate_title"]];
        if ([self checkMatch:theshowtitle alttitle:alttitle regex:regex option:i]) {
            if ([[NSString stringWithFormat:@"%@", [searchentry objectForKey:@"show_type"]] isEqualToString:@"TV"]) { // Check Seasons if the title is a TV show type
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
        [self addtoCache:DetectedTitle showid:titleid];
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
            if (confirmed) { // Will only store actual title if confirmation feature is not turned on
                // Store Actual Title
                LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",[LastScrobbledInfo objectForKey:@"title"]];
            }
            DetectedCurrentEpisode = LastScrobbledEpisode;
            LastScrobbledSource = DetectedSource;
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
-(NSDictionary *)detectStream{
    // Create Dictionary
    NSDictionary * d;
    //Set detectream Task and Run it
    NSTask *task;
    task = [[NSTask alloc] init];
    NSBundle *myBundle = [NSBundle mainBundle];
    [task setLaunchPath:[myBundle pathForResource:@"detectstream" ofType:@""]];
        
        
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // Reads Output
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    // Launch Task
    [task launch];
    
    // Parse Data from JSON and return dictionary
    NSData *data;
    data = [file readDataToEndOfFile];
        
        
    NSError* error;

    d = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return d;
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
-(void)addtoCache:(NSString *)title showid:(NSString *)showid{
    //Adds ID to cache
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
    NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys:title, @"detectedtitle", showid, @"showid", nil];
    [cache addObject:entry];
    [defaults setObject:cache forKey:@"searchcache"];
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
-(bool)checkifIgnored:(NSString *)filename{
    //Checks if file name or directory is on ignore list
    filename = [filename stringByReplacingOccurrencesOfString:@"n/" withString:@"/"];
    //Check ignore directories. If on ignore directory, set onIgnoreList to true.
    NSArray * ignoredirectories = [[NSUserDefaults standardUserDefaults] objectForKey:@"ignoreddirectories"];
    if ([ignoredirectories count] > 0) {
        for (NSDictionary * d in ignoredirectories) {
            if ([[OGRegularExpression regularExpressionWithString:[[NSString stringWithFormat:@"^(%@/)+", [d objectForKey:@"directory"]] stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"] options:OgreIgnoreCaseOption] matchInString:filename]) {
                NSLog(@"Video being played is in ignored directory");
                return true;
                break;
            }
        }
    }
    // Get filename only
    filename = [[OGRegularExpression regularExpressionWithString:@"^.+/"] replaceAllMatchesInString:filename withString:@""];
    NSArray * ignoredfilenames = [[NSUserDefaults standardUserDefaults] objectForKey:@"IgnoreTitleRules"];
    if ([ignoredfilenames count] > 0) {
        for (NSDictionary * d in ignoredfilenames) {
            NSString * rule = [NSString stringWithFormat:@"%@", [d objectForKey:@"rule"]];
            if ([[OGRegularExpression regularExpressionWithString:rule options:OgreIgnoreCaseOption] matchInString:filename] && rule.length !=0) { // Blank rules are infinite, thus should not be counted
                NSLog(@"Video file name is on filename ignore list.");
                return true;
                break;
            }
        }
    }
    return false;
}
-(void)checkExceptions{
    NSLog(@"Check Exceptions List");
    // Check Exceptions
    NSArray *exceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"];
    if (exceptions.count > 0) {
        NSString * correcttitle;
        for (NSDictionary *d in exceptions) {
            NSString * title = [d objectForKey:@"detectedtitle"];
            if ([title isEqualToString:DetectedTitle]) {
                NSLog(@"%@ found on exceptions list as %@!", title, [d objectForKey:@"correcttitle"]);
                correcttitle = [d objectForKey:@"correcttitle"];
                break;
            }
        }
        if (correcttitle.length > 0) {
            DetectedTitle = correcttitle;
            // Remove Season to avoid conflicts
            DetectedSeason = 0;
        }
    }
}
@end
