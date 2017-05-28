//
//  ExceptionsCache.h
//  Hachidori
//
//  Created by Tail Red on 2/1/15.
//
//

#import <Foundation/Foundation.h>

@interface ExceptionsCache : NSObject
+ (void)addtoExceptions:(NSString *)detectedtitle correcttitle:(NSString *)title aniid:(NSString *)showid threshold:(int)threshold offset:(int)offset;
+ (void)checkandRemovefromCache:(NSString *)detectedtitle;
+ (void)addtoCache:(NSString *)title showid:(NSString *)showid actualtitle:(NSString *) atitle totalepisodes:(int)totalepisodes ;
@end
