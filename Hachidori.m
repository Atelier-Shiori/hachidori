//
//  Hachidori.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import "Recognition.h"

@interface Hachidori ()
// Private Methods
-(int)detectmedia; // 0 - Nothing, 1 - Same, 2 - Update
-(NSString *)searchanime;
-(NSString *)findaniid:(NSData *)ResponseData;
-(BOOL)checkstatus:(NSString *)titleid;
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug;
-(int)updatetitle:(NSString *)titleid;
-(NSDictionary *)detectStream;
-(void)populateStatusData:(NSDictionary *)d;
//-(int)recognizeSeason:(NSString *)season;
-(int)countWordsInTitle:(NSString *) title;
-(BOOL)checkillegalcharacters:(NSString *) title;
-(void)addtoCache:(NSString *)title showid:(NSString *)showid;
@end

@implementation Hachidori

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

/*
 
 Update Methods
 
 */

- (int)startscrobbling {
    // 0 - nothing playing; 1 - same episode playing; 21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed; 
    int detectstatus;
	//Set up Delegate
	
    detectstatus = [self detectmedia];
	if (detectstatus == 2) { // Detects Title
        return [self scrobble];
	}

    return detectstatus;
}
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode{
    DetectedTitle = showtitle;
    DetectedEpisode = episode;
    return [self scrobble];
}
-(int)scrobble{
    int status;
    NSLog(@"Getting AniID");
    if ([self countWordsInTitle:DetectedTitle] == 1 && ![self checkillegalcharacters:DetectedTitle]) {
        //Single title, set as ID
        NSLog(@"Single Title");
        AniID = DetectedTitle.lowercaseString;
    }
    else {
        // Regular Search
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
            NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
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
    }
    if (AniID.length > 0) {
        NSLog(@"Found %@", AniID);
        // Check Status and Update
        BOOL UpdateBool = [self checkstatus:AniID];
        if (UpdateBool == 1) {
            if (LastScrobbledTitleNew) {
                //Title is not on list. Add Title
                int s = [self updatetitle:AniID];
                if (s == 21) {
                    Success = true;}
                else{
                    Success = false;}
                status = s;
            }
            else {
                // Update Title as Usual
                int s = [self updatetitle:AniID];
                if (s == 1 || s == 22) {
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
    DetectedCurrentEpisode = nil;
    
    // Release Detected Title/Episode.
    return status;
}
-(NSString *)searchanime{
    NSLog(@"Check Exceptions List");
    // Check Exceptions
    NSMutableArray *exceptions = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"]];
    if (exceptions.count > 0) {
        NSString * theid;
        for (NSDictionary *d in exceptions) {
            NSString * title = [d objectForKey:@"detectedtitle"];
            if ([title isEqualToString:DetectedTitle]) {
                NSLog(@"%@ found on exceptions list as %@!", title, [d objectForKey:@"correcttitle"]);
                theid = [d objectForKey:@"showid"];
                break;
            }
        }
        if (theid.length > 0) {
            return theid;
        }
    }
    // Begin Search
	NSLog(@"Searching For Title");
    // Set Season for Search Term if any detected.
    NSString * searchtitle;
    if (DetectedSeason > 1) {
        searchtitle = [NSString stringWithFormat:@"%@ %i season", [self desensitizeSeason:DetectedTitle], DetectedSeason];
    }
    else
        searchtitle = DetectedTitle;
	//Escape Search Term
	NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
																				NULL,
																				(CFStringRef)searchtitle,
																				NULL,
																				(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																				kCFStringEncodingUTF8 ));
	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/search/anime?query=%@",@"https://hbrd-v1.p.mashape.com", searchterm]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
    //Set Timeout
    [request setTimeOutSeconds:15];
	//Perform Search
	[request startSynchronous];
	//Set up Delegate
	
	// Get Status Code
	int statusCode = [request responseStatusCode];
    NSData *response = [request responseData];
	switch (statusCode) {
        case 0:
            online = false;
            Success = NO;
            return @"";
            break;
		case 200:
            online = true;
			return [self findaniid:response];
			break;
			
		default:
            online = true;
			Success = NO;
			return @"";
			break;
	}
	
}
-(int)detectmedia {
	//Set up Delegate
	//
	// LSOF mplayer to get the media title and segment

    NSArray * player = [NSArray arrayWithObjects:@"mplayer", @"mpv", @"mplayer-mt", @"VLC", @"QuickTime Playe", @"QTKitServer", nil];
    NSString *string;
	
    for(int i = 0; i <[player count]; i++){
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/sbin/lsof"];
    [task setArguments: [NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@", [player objectAtIndex:i]], @"-F", @"n", nil]]; 		//lsof -c '<player name>' -Fn
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];

    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    if (string.length > 0)
        break;
    }
	if (string.length > 0) {
		//Regex time
		//Get the filename first
		OGRegularExpression    *regex = [OGRegularExpression regularExpressionWithString:@"^.+(avi|mkv|mp4|ogm)$"];
		NSEnumerator    *enumerator;
		enumerator = [regex matchEnumeratorInString:string];
        OGRegularExpressionMatch    *match;
		while ((match = [enumerator nextObject]) != nil) {
			string = [match matchedString];
		}
        NSDictionary *d = [[Recognition alloc] recognize:string];
        DetectedTitle = [NSString stringWithFormat:@"%@", [d objectForKey:@"title"]];
        DetectedEpisode = [NSString stringWithFormat:@"%@", [d objectForKey:@"episode"]];
        DetectedSeason = [[d objectForKey:@"season"] intValue];
        DetectedisStream = false;
        goto update;
	}
	else {
        NSLog(@"Checking Stream...");
        NSDictionary * detected = [self detectStream];
        
        if ([detected objectForKey:@"result"]  == [NSNull null]){ // Check to see if anything is playing on stream
            return 0;
        }
        else{
            NSArray * c = [detected objectForKey:@"result"];
            NSDictionary * d = [c objectAtIndex:0];
            DetectedTitle = [NSString stringWithFormat:@"%@",[d objectForKey:@"title"]];
            DetectedEpisode = [NSString stringWithFormat:@"%@",[d objectForKey:@"episode"]];
            DetectedisStream = true;
            goto update;
        }
		// Nothing detected
	}
update:
    // Check if the title was previously scrobbled
    if ([DetectedTitle isEqualToString:LastScrobbledTitle] && [DetectedEpisode isEqualToString: LastScrobbledEpisode] && Success == 1) {
        // Do Nothing
        return 1;
    }
    else {
        // Not Scrobbled Yet or Unsuccessful
        return 2;
    }
}
-(NSString *)findaniid:(NSData *)ResponseData {
	// Initalize JSON parser
    NSError* error;
    
	NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
	NSString *titleid = @"";
	//Initalize NSString to dump the title temporarily
	NSString *theshowtitle = @"";
    NSString *theshowtype = @"";
	//Create Regular Expression Strings
	NSString *findpre = [NSString stringWithFormat:@"(%@)",DetectedTitle];
    NSString *findinit = [NSString stringWithFormat:@"(%@)",DetectedTitle];
	findpre = [findpre stringByReplacingOccurrencesOfString:@" " withString:@"|"]; // NSString *findpre = [NSString stringWithFormat:@"^%@",DetectedTitle];
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
    // Initalize Arrays for each Media Type
    NSMutableArray * movie = [[NSMutableArray alloc] init];
    NSMutableArray * tv = [[NSMutableArray alloc] init];
    NSMutableArray * ova = [[NSMutableArray alloc] init];
    NSMutableArray * special = [[NSMutableArray alloc] init];
    NSMutableArray * other = [[NSMutableArray alloc] init];
    // Organize Them
    for (NSDictionary *entry in searchdata) {
        theshowtype = [NSString stringWithFormat:@"%@", [entry objectForKey:@"show_type"]];
        if ([theshowtype isEqualToString:@"Movie"])
            [movie addObject:entry];
        else if ([theshowtype isEqualToString:@"TV"])
            [tv addObject:entry];
        else if ([theshowtype isEqualToString:@"OVA"])
            [ova addObject:entry];
        else if ([theshowtype isEqualToString:@"Special"])
            [special addObject:entry];
        else if (![theshowtype isEqualToString:@"Music"])
            [other addObject:entry];
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
        for (NSDictionary *searchentry in movie) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
        }
            DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
            goto foundtitle;
        }
        //Check movies and Specials First
        for (NSDictionary *searchentry in special) {
            theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
            if ([regex matchInString:theshowtitle] != nil) {
                DetectedEpisode = @"1";
                DetectedTitleisMovie = false;
                //Return titleid
                titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
                goto foundtitle;
            }
        }
    }
    // Check TV, Special, OVA, Other
    for (NSDictionary *searchentry in tv) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
            // Used for Season Checking
            OGRegularExpression    *regex2 = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"%i(st|nd|rd|th) season", DetectedSeason] options:OgreIgnoreCaseOption];
            OGRegularExpressionMatch * smatch = [regex2 matchInString:theshowtitle];
            if (DetectedSeason >= 2) { // Season detected, check to see if there is a matcch. If not, continue.
                if (smatch == nil) {
                    continue;
                }
            }
            else{
                if (smatch != nil) { // No Season, check to see if there is a season or not. If so, continue.
                    continue;
                }
            }
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
            goto foundtitle;
        }
    }
    for (NSDictionary *searchentry in special) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
            goto foundtitle;
        }
    }
    for (NSDictionary *searchentry in ova) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
            goto foundtitle;
        }
    }
    for (NSDictionary *searchentry in other) {
        theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
            goto foundtitle;
        }
    }
     }
    foundtitle:
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"]) {
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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/libraries/%@", @"https://hbrd-v1.p.mashape.com", titleid]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
    //Ignore Cookies
    [request setUseCookiePersistence:NO];
    //Set Token
    [request setPostValue:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    //Set Timeout
    [request setTimeOutSeconds:15];
    // Get Information
    [request startSynchronous];
    NSDictionary * d;
    int statusCode = [request responseStatusCode];
	if (statusCode == 200 || statusCode == 201 ) {
        online = true;
        //return Data
        NSError * error;
        d = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&error];
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
		// Makes sure the values don't get released
		return YES;
	}
    else if (statusCode == 0){
        online = false;
        return NO;
    }
	else {
		// Some Error. Abort
		//Set up Delegate
		//
		//[appDelegate setStatusText:@"Scrobble Status: Scrobble Failed. Retrying in 5 mins..."];
		return NO;
	}
	//Should never happen, but...
	return NO;
}
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug{
    NSLog(@"Getting Additional Info");
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/%@",@"https://hbrd-v1.p.mashape.com", slug]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
    //Ignore Cookies
    [request setUseCookiePersistence:NO];
    //Perform Search
    [request startSynchronous];
    // Get Status Code
    int statusCode = [request responseStatusCode];
    if (statusCode == 200) {
        NSError* error;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&error];
        return d;
    }
    else{
        NSDictionary * d = [[NSDictionary alloc] init];
        return d;
    }
}
-(int)updatetitle:(NSString *)titleid {
	NSLog(@"Updating Title");
	//Set up Delegate
	
	if ([DetectedEpisode intValue] <= [DetectedCurrentEpisode intValue] ) { 
		// Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
        return 1;
	}
	else {
		// Update the title
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//Set library/scrobble API
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/libraries/%@", @"https://hbrd-v1.p.mashape.com", titleid]];
		ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
		//Ignore Cookies
		[request setUseCookiePersistence:NO];
		//Set Token
		[request setPostValue:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
        //Set Timeout
        [request setTimeOutSeconds:15];
	    //[request setRequestMethod:@"PUT"];
	    [request setPostValue:DetectedEpisode forKey:@"episodes_watched"];
		//Set Status
		if([DetectedEpisode intValue] == [TotalEpisodes intValue]) {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"completed";
			// Since Detected Episode = Total Episode, set the status as "Complete"
			[request setPostValue:WatchStatus forKey:@"status"];
		}
		else {
			//Set Title State for Title (use for Twitter feature)
			WatchStatus = @"currently-watching";
			// Still Watching
			[request setPostValue:WatchStatus forKey:@"status"];
		}	
		// Set existing score to prevent the score from being erased.
		[request setPostValue:TitleScore forKey:@"rating"];
        //Privacy
        if (isPrivate)
            [request setPostValue:@"private" forKey:@"privacy"];
        else
            [request setPostValue:@"public" forKey:@"privacy"];
		// Do Update
		[request startSynchronous];
		
		// Store Scrobbled Title and Episode
		LastScrobbledTitle = DetectedTitle;
		LastScrobbledEpisode = DetectedEpisode;
		//NSLog(@"%i", [request responseStatusCode]);
        
		switch ([request responseStatusCode]) {
			case 201:
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
}
-(BOOL)updatestatus:(NSString *)titleid
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
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/libraries/%@", @"https://hbrd-v1.p.mashape.com", titleid]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Set Token
    [request setPostValue:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
	//Set current episode
	//[request setPostValue:LastScrobbledEpisode forKey:@"episodes"];
	//Set new watch status
	[request setPostValue:showwatchstatus forKey:@"status"];	
	//Set new score.
	[request setPostValue:[NSString stringWithFormat:@"%f", showscore] forKey:@"rating"];
    //Set new note
    [request setPostValue:note forKey:@"notes"];
    //Privacy
    if (privatevalue)
        [request setPostValue:@"private" forKey:@"privacy"];
    else
        [request setPostValue:@"public" forKey:@"privacy"];
    //Set Timeout
    [request setTimeOutSeconds:15];
	// Do Update
	[request startSynchronous];
    switch ([request responseStatusCode]) {
        case 200:
		case 201:
                //Set New Values
                TitleScore = [NSString stringWithFormat:@"%f", showscore];
                WatchStatus = showwatchstatus;
                TitleNotes = note;
                isPrivate = privatevalue;
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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/libraries/%@/remove", @"https://hbrd-v1.p.mashape.com", titleid]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
    //Ignore Cookies
    [request setUseCookiePersistence:NO];
    //Set Token
    [request setPostValue:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    //Set Timeout
    [request setTimeOutSeconds:15];
    // Do Update
    [request startSynchronous];
    switch ([request responseStatusCode]) {
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

-(NSString *)desensitizeSeason:(NSString *)title {
    // Get rid of season references
    OGRegularExpression* regex = [OGRegularExpression regularExpressionWithString: @"(Second Season|Third Season|Fourth Season|Fifth Season|Sixth Season|Seventh Season|Eighth Season|Nineth Season)"];
    title = [regex replaceAllMatchesInString:title withString:@"" options:OgreIgnoreCaseOption];
    regex = [OGRegularExpression regularExpressionWithString: @"(s|S)\\d"];
    title = [regex replaceAllMatchesInString:title withString:@"" options:OgreIgnoreCaseOption];
    // Remove any Whitespace
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}
-(int)countWordsInTitle:(NSString *) title{
    // Counts amount of words in the title
    NSCountedSet * count = [NSCountedSet new];
    [title enumerateSubstringsInRange:NSMakeRange(0, [title length])
                              options:NSStringEnumerationByWords | NSStringEnumerationLocalized
                           usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
                               [count addObject:substring];
                           }];
    return [count count];
}
-(BOOL)checkillegalcharacters:(NSString *) title{
    //Checks if the single word is suitable to be used as a slug.
    NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789"] invertedSet];
    
    if ([title rangeOfCharacterFromSet:set].location != NSNotFound) {
        return true;
    }
    return false;
}
-(void)addtoCache:(NSString *)title showid:(NSString *)showid{
    //Adds ID to cache
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *cache = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]];
    NSDictionary * entry = [[NSDictionary alloc] initWithObjectsAndKeys:title, @"detectedtitle", showid, @"showid", nil];
    [cache addObject:entry];
    [defaults setObject:cache forKey:@"searchcache"];
}
@end
