//
//  Hachidori+Twitter.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/30.
//

#import "Hachidori+Twitter.h"
#import <TwitterManagerKit/TwitterManagerKit.h>

@implementation Hachidori (Twitter)
- (void)postaddanimetweet {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitteraddanime"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"] && !self.testing) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitteraddanimeformat"]];
    }
}
- (void)postupdateanimetweet {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitterupdateanime"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"] && !self.testing) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitterupdateanimeformat"]];
    }
}
- (void)postupdatestatustweet {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"twitterupdatestatus"] && [NSUserDefaults.standardUserDefaults boolForKey:@"tweetonscrobble"] && !self.testing) {
        [self performtweet:[NSUserDefaults.standardUserDefaults objectForKey:@"twitterupdatestatusformat"]];
    }
}

- (void)performtweet:(NSString *)format {
    if ([self.twittermanager accountexists]) {
        [self.twittermanager postTweet:[self generateTweetStringWithFormat:format] completion:^(bool success) {
            if (success) {
                NSLog(@"Tweet successful.");
            }
        } error:^(NSError *error) {
            NSLog(@"Error posting tweet: %@", error.localizedDescription);
        }];
    }
}

- (NSString *)generateTweetStringWithFormat:(NSString *)formatstring {
    NSString *tmpstr = formatstring;
    // Replace $title% with actual title
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%title%" withString:self.lastscrobble.LastScrobbledActualTitle];
    // Replace %status% with actual status
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%status%" withString:self.lastscrobble.WatchStatus];
    // Replace %episode% with actual episode number
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%episode%" withString:self.lastscrobble.LastScrobbledEpisode];
    // Replace %malurl% with actual MAL URL
    switch (self.currentService) {
        case 0:
            tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%url%" withString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", self.lastscrobble.AniID]];
            break;
        case 1:
            tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%url%" withString:[NSString stringWithFormat:@"https://anilist.co/anime/%@", self.lastscrobble.AniID]];
            break;
        default:
            break;
    }
    // Replace %score$ with the actual score
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%score%" withString:[NSString stringWithFormat:@"%i/10", self.lastscrobble.TitleScore]];
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"%service%" withString:self.currentServiceName];
    return tmpstr;
}
@end
