//
//  Hachidori+UserStatus.h
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "Hachidori.h"

@interface Hachidori (UserStatus)
-(BOOL)checkstatus:(NSString *)titleid;
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug;
-(void)populateStatusData:(NSDictionary *)d;
@end
