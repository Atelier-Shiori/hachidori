//
//  Hachidori+Search.h
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"

@interface Hachidori (Search)
-(NSString *)searchanime;
-(NSString *)performSearch:(NSString *)searchtitle;
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term;
-(NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found;
-(NSArray *)filterArray:(NSArray *)searchdata;
-(NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b;
@end
