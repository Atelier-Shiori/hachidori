//
//  BrowserDetection.h
//  detectstream
//
//  Created by 高町なのは on 2015/02/09.
//  Copyright 2014-2018 Atelier Shiori, James Moy. All rights reserved. Code licensed under MIT License.
//
//  This class gathers all the page titles, url and DOM (if necessary) from open browsers.
//  Only returns applicable streaming sites.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface BrowserDetection : NSObject
+ (NSArray *)getPages;
- (BOOL)checkIdentifier:(NSString*)identifier;
- (NSString *)checkURL:(NSString *)url;
@end
