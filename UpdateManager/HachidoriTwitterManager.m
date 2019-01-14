//
//  HachidoriTwitterManager.m
//  Hachidori
//
//  Created by 香風智乃 on 1/14/19.
//

#import "HachidoriTwitterManager.h"
#import "LastScrobbleStatus.h"
#import <TwitterManagerKit/TwitterManagerKit.h>
#import "ClientConstants.h"
#import "Hachidori.h"

@implementation HachidoriTwitterManager
- (instancetype)init {
    if (self = [super init]) {
        // Init Twitter Manager
        self.twittermanager = [[TwitterManager alloc] initWithConsumerKeyUsingFirstAccount:kConsumerKey withConsumerSecret:kConsumerSecret];
    }
    return self;
}

- (void)postaddanimetweet:(LastScrobbleStatus *)lastscrobbled {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitteraddanime"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"]) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitteraddanimeformat"] withLastScrobbled:lastscrobbled];
    }
}

- (void)postupdateanimetweet:(LastScrobbleStatus *)lastscrobbled {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitterupdateanime"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"]) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitterupdateanimeformat"] withLastScrobbled:lastscrobbled];
    }
}

- (void)postupdatestatustweet:(LastScrobbleStatus *)lastscrobbled {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitterupdatestatus"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"]) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitterupdatestatusformat"] withLastScrobbled:lastscrobbled];
    }
}

- (void)performtweet:(NSString *)format withLastScrobbled:(LastScrobbleStatus *)lastscrobbled {
    if ([self.twittermanager accountexists]) {
        [self.twittermanager postTweet:[self generateTweetStringWithFormat:format withLastScrobbled:lastscrobbled] completion:^(bool success) {
            if (success) {
                NSLog(@"Tweet successful.");
            }
        } error:^(NSError *error) {
            NSLog(@"Error posting tweet: %@", error.localizedDescription);
        }];
    }
}

- (NSString *)generateTweetStringWithFormat:(NSString *)formatstring withLastScrobbled:(LastScrobbleStatus *)lastscrobbled{
    NSString *tmpstr = formatstring;
    // Replace $title% with actual title
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%title%" withString:lastscrobbled.LastScrobbledActualTitle];
    // Replace %status% with actual status
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%status%" withString:lastscrobbled.WatchStatus];
    // Replace %episode% with actual episode number
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%episode%" withString:lastscrobbled.LastScrobbledEpisode];
    // Replace %malurl% with actual MAL URL
    switch ([Hachidori currentService]) {
        case 0:
            tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%url%" withString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", lastscrobbled.AniID]];
            break;
        case 1:
            tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%url%" withString:[NSString stringWithFormat:@"https://anilist.co/anime/%@", lastscrobbled.AniID]];
            break;
        default:
            break;
    }
    // Replace %score$ with the actual score
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%score%" withString:[NSString stringWithFormat:@"%i/10", lastscrobbled.TitleScore]];
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%service%" withString:[Hachidori currentServiceName]];
    return tmpstr;
}
@end
