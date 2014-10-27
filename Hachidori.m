//
//  Hachidori.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"

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
    int status, detectstatus;
	//Set up Delegate
	
    detectstatus = [self detectmedia];
	if (detectstatus == 2) { // Detects Title
		
		NSLog(@"Getting AniID");
		AniID = [self searchanime];
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
                status = 54;
            }
		}
		else {
			// Not Successful
            status = 51;
			
		}
		// Empty out Detected Title/Episode to prevent same title detection
		DetectedTitle = @"";
		DetectedEpisode = @"";
        // Release Detected Title/Episode.
        return status;
	}

    return detectstatus;
}
-(NSString *)searchanime{
	NSLog(@"Searching For Title");
	//Escape Search Term
	NSString * searchterm = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
																				NULL,
																				(CFStringRef)DetectedTitle,
																				NULL,
																				(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																				kCFStringEncodingUTF8 ));
	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/search/anime?query=%@",@"https://hbrd-v1.p.mashape.com/", searchterm]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Perform Search
	[request startSynchronous];
	//Set up Delegate
	
	// Get Status Code
	int statusCode = [request responseStatusCode];
    NSData *response = [request responseData];
	switch (statusCode) {
		case 200:
			return [self findaniid:response];
			break;
			
		default:
			Success = NO;
			return @"";
			break;
	}
	
}
-(int)detectmedia {
	//Set up Delegate
	//
	// LSOF mplayer to get the media title and segment

    NSArray * player = [NSArray arrayWithObjects:@"mplayer", @"mpv", @"VLC", @"QTKitServer", nil];
    NSString *string;
	
    for(int i = 0; i <4; i++){
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
		//Accented e temporary fix
		regex = [OGRegularExpression regularExpressionWithString:@"e\\\\xcc\\\\x81"];
		string = [regex replaceAllMatchesInString:string
									   withString:@"è"];
		//Cleanup
		regex = [OGRegularExpression regularExpressionWithString:@"^.+/"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"\\.\\w+$"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\[[^\\]]+\\]\\s*"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"[\\s_]*\\([^\\)]+\\)$"];
		string = [regex replaceAllMatchesInString:string
									   withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"_"];
		string = [regex replaceAllMatchesInString:string
									   withString:@" "];
        regex = [OGRegularExpression regularExpressionWithString:@"~"];
        string = [regex replaceAllMatchesInString:string
                                       withString:@""];
        regex = [OGRegularExpression regularExpressionWithString:@"-"];
        string = [regex replaceAllMatchesInString:string
                                       withString:@""];
		// Set Title Info
		regex = [OGRegularExpression regularExpressionWithString:@"( \\-) (episode |ep |ep|e)?(\\d+)([\\w\\-! ]*)$"];
		DetectedTitle = [regex replaceAllMatchesInString:string
														 withString:@""];
        regex = [OGRegularExpression regularExpressionWithString: @"\\b\\S\\d+$"];
        DetectedTitle = [regex replaceAllMatchesInString:DetectedTitle
                                              withString:@""];
		// Set Episode Info
		regex = [OGRegularExpression regularExpressionWithString: DetectedTitle];
		string = [regex replaceAllMatchesInString:string
												withString:@""];
		regex = [OGRegularExpression regularExpressionWithString:@"v[\\d]"];
		DetectedEpisode = [regex replaceAllMatchesInString:string
												withString:@""];
        
		// Trim Whitespace
		DetectedTitle = [DetectedTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		DetectedEpisode = [DetectedEpisode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
	//Set Regular Expressions to omit any preceding words
	NSString *findpre = [NSString stringWithFormat:@"(%@)",DetectedTitle];
	findpre = [findpre stringByReplacingOccurrencesOfString:@" " withString:@"|"]; // NSString *findpre = [NSString stringWithFormat:@"^%@",DetectedTitle];
	OGRegularExpression    *regex = [OGRegularExpression regularExpressionWithString:findpre options:OgreIgnoreCaseOption];

	//Retrieve the ID. Note that the most matched title will be on the top
    BOOL idok; // Checks the status
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
    NSMutableArray * checkAgain = [[NSMutableArray alloc] init];
	for (NSDictionary *searchentry in searchdata) {
		//Store title from search entry
		theshowtitle = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"title"]];
        theshowtype = [NSString stringWithFormat:@"%@", [searchentry objectForKey:@"show_type"]];
        // Checks to make sure Hachidori is updating the correct type of show
        if (DetectedTitleisMovie) {
            if ([theshowtype isEqualToString:@"Movie"]) {
                DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                idok = true;
            }
            else if([DetectedEpisode intValue] == 0 && [theshowtype isEqualToString:@"Special"]){
                //Specials are usually one episode (although there are exceptions
                DetectedEpisode = @"1";
                DetectedTitleisMovie = false;
                idok = true;
            }
            else {
                idok = false;
            }
        }
        else if([theshowtype isEqualToString:@"Movie"]){
            idok = false; // Rejects result, not a movie.
            continue;
        }
        else if([theshowtype isEqualToString:@"Music"]|| ([theshowtype isEqualToString:@"ONA"] && !DetectedisStream)){
            idok = false; // Rejects Hachidori only scrobbles movies, Anime, OVAs or specials. ONAs id most likely from a stream source.
        }
        else if([DetectedEpisode intValue] > 0 && [theshowtype isEqualToString:@"Special"]){
            //Specials are usually one episode (although there are exceptions
            idok = false;
        }
        else if ([theshowtype isEqualToString:@"TV"]|| [theshowtype isEqualToString:@"OVA"]){
            //OK to go
            idok = true;
        }
        if (idok) { // Good to go, check the title with regular expressions
            if ([regex matchInString:theshowtitle] != nil) {
                //Return titleid
                titleid = [NSString stringWithFormat:@"%@",[searchentry objectForKey:@"slug"]];
                goto foundtitle;
                
            }
        }
        else {[checkAgain addObject:searchentry];}
    }
    // Check the remaining titles for a match
    for (NSDictionary * d in checkAgain ) {
        theshowtitle = [NSString stringWithFormat:@"%@",[d objectForKey:@"title"]];
        if ([regex matchInString:theshowtitle] != nil) {
            //Return titleid
            titleid = [NSString stringWithFormat:@"%@",[d objectForKey:@"slug"]];
            goto foundtitle;
            
        }
    }
foundtitle:
	//Return the AniID
	return titleid;
}
-(BOOL)checkstatus:(NSString *)titleid {
	NSLog(@"Checking Status");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//Set Search API
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@/library",@"https://hbrd-v1.p.mashape.com/", [defaults objectForKey:@"Username"]]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
	//Ignore Cookies
	[request setUseCookiePersistence:NO];
	//Perform Search
	[request startSynchronous];
	// Get Status Code
	int statusCode = [request responseStatusCode];
    NSData *response = [request responseData];
	if (statusCode == 200 ) {
        NSDictionary * tmpinfo;
		// Initalize JSON parser
        NSError* error;
		NSArray *animelist = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&error];
        for (int i = 0; i< [animelist count]; i++) {
            NSDictionary * d = [animelist objectAtIndex:i];
            NSDictionary * tmp = [d objectForKey:@"anime"];
            NSString * tmpslug = [tmp objectForKey:@"slug"];
            if ([titleid isEqualToString:tmpslug]) {
                [self populateStatusData:d];
                break;
            }
            else {
            }
            if (i == [animelist count] - 1) {
                //Title not on list, mark it as new
                tmpinfo = [self retrieveAnimeInfo:AniID];
                NSLog(@"Not on List or private");
                NSDictionary * n = [self getTitlePrivateInfo:AniID];
                if ([n count] > 0) {
                    [self populateStatusData:n];
                }
                else{
                    WatchStatus = @"currently-watching";
                    LastScrobbledInfo = tmpinfo;
                    DetectedCurrentEpisode = @"0";
                    LastScrobbledTitleNew = true;
                }
                break;
            }
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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/anime/%@",@"https://hbrd-v1.p.mashape.com/", slug]];
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
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/libraries/%@", @"https://hbrd-v1.p.mashape.com/", titleid]];
		ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
		//Ignore Cookies
		[request setUseCookiePersistence:NO];
		//Set Token
		[request setPostValue:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
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
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/libraries/%@", @"https://hbrd-v1.p.mashape.com/", titleid]];
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
        
	// Do Update
	[request startSynchronous];
	NSLog(@"%i", [request responseStatusCode]);
	switch ([request responseStatusCode]) {
        case 200:
		case 201:
			// Update Successful
			if ([TitleScore floatValue] == showscore && [WatchStatus isEqualToString:showwatchstatus] && [note isEqualToString:TitleNotes])
			{
				//Nothing changed, do nothing.
			}
			else {
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
-(NSDictionary *) getTitlePrivateInfo:(NSString*)aniid{
    
    NSLog(@"Checking %@", aniid);
    //Set up Delegate
    
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/libraries/%@", @"https://hbrd-v1.p.mashape.com/", aniid]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request addRequestHeader:@"X-Mashape-Key" value:mashapekey];
    //Ignore Cookies
    [request setUseCookiePersistence:NO];
    //Set Token
    [request setPostValue:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    // Get Information
    [request startSynchronous];
    NSDictionary * d;
    switch ([request responseStatusCode]) {
        case 200:
        case 201:{
            //return Data
            NSError * error;
            d = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&error];
            return d;
            break;
        }
        default:
            d = [[NSDictionary alloc] init];
            return d;
            break;
    }
}
-(void)populateStatusData:(NSDictionary *)d{
    // Info is there.
    NSDictionary * tmpinfo = [d objectForKey:@"anime"];
    NSLog(@"Title on List");
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
    NSLog(@"Title Score %@", TitleScore);
    DetectedCurrentEpisode = [d objectForKey:@"episodes_watched"];
    LastScrobbledInfo = tmpinfo;
    LastScrobbledTitleNew = false;
}

@end
